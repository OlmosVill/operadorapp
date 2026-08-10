import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Estado mecánico del tracto. Espeja el enum planeado en
/// `docs/features/truck-animation.md`; cuando exista
/// `core/services/truck_telemetry_service.dart` debe moverse allá y este
/// archivo importarlo.
enum MechanicalState { ok, flatTire, inService, crashed }

/// Escena lateral animada del tracto, portada 1:1 del export de Claude Design.
///
/// El mockup la resuelve con CSS + SVG; aquí es un único `CustomPaint` porque
/// las capas comparten reloj y todas las medidas del diseño son porcentajes de
/// la altura del contenedor. Un árbol de `Positioned` daría el mismo dibujo con
/// mucho más ruido y un repintado peor.
///
/// Sustituye al `.riv` que esperaba `truck-animation.md`: la máquina de estados
/// (marcha / detenido / llanta / taller / accidentado) ya viene resuelta.
class TruckScene extends StatefulWidget {
  const TruckScene({
    required this.speedKmh,
    required this.timeOfDay,
    required this.mechanical,
    required this.progress,
    super.key,
  });

  /// Velocidad cruda de telemetría, en km/h. El estado mecánico la recorta.
  final double speedKmh;

  /// Hora decimal 0–24. Decide cielo, faros y estrellas.
  final double timeOfDay;

  final MechanicalState mechanical;

  /// Avance del viaje 0–1. Coloca el tracto entre el 22% y el 76% del ancho.
  final double progress;

  @override
  State<TruckScene> createState() => _TruckSceneState();
}

class _TruckSceneState extends State<TruckScene>
    with SingleTickerProviderStateMixin {
  final _clock = _SceneClock();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    unawaited(_ticker.start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    // El primer frame trae un delta inútil; y si la app estuvo en pausa el
    // salto sería enorme, así que se acota.
    if (dt <= 0 || dt > 0.5) return;
    _clock.advance(dt, _timing());
  }

  /// Velocidad efectiva: una llanta ponchada obliga a bajar a 20 km/h y taller
  /// o accidente dejan el tracto quieto.
  double get _effectiveSpeed => switch (widget.mechanical) {
        MechanicalState.flatTire => math.min(widget.speedKmh, 20),
        MechanicalState.inService || MechanicalState.crashed => 0,
        MechanicalState.ok => widget.speedKmh,
      };

  _SceneTiming _timing() {
    final speed = _effectiveSpeed;
    final stopped = speed <= 0;
    // Parallax por capa según docs/features/truck-animation.md:
    // FarBg speed*0.05 · MidBg *0.2 · Poles *0.7 · Road *1.0
    final base = 46 / math.max(6, speed);

    return _SceneTiming(
      stopped: stopped,
      road: base,
      poles: base / 0.7,
      mid: base / 0.2,
      far: base / 0.05,
      wheel: base * 0.09,
      gust: base * 0.42,
      bob: math.max(0.32, 80 / math.max(20, speed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speed = _effectiveSpeed;
    final palette = _ScenePalette.forHour(widget.timeOfDay);

    return ClipRect(
      child: CustomPaint(
        painter: _TruckScenePainter(
          clock: _clock,
          palette: palette,
          mechanical: widget.mechanical,
          stopped: speed <= 0,
          gusting: speed > 0 && speed >= 88,
          gustOpacity: math.min(0.55, (speed - 80) / 70),
          progress: widget.progress.clamp(0.0, 1.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

// ─── Reloj ──────────────────────────────────────────────────────────────────

/// Fases normalizadas 0–1 de cada capa.
///
/// Se avanzan por incrementos en vez de derivarse de un tiempo absoluto: así un
/// cambio de velocidad acelera el desplazamiento sin dar el brinco que produce
/// recalcular `elapsed / duración` con otra duración.
class _SceneClock extends ChangeNotifier {
  double road = 0;
  double poles = 0;
  double mid = 0;
  double far = 0;
  double wheel = 0;
  double gust = 0;
  double bob = 0;
  double smoke = 0;

  void advance(double dt, _SceneTiming t) {
    // El tracto respira y humea aunque esté parado; el paisaje no.
    bob = (bob + dt / t.bob) % 1;
    smoke = (smoke + dt / 1.6) % 1;

    if (!t.stopped) {
      road = (road + dt / t.road) % 1;
      poles = (poles + dt / t.poles) % 1;
      mid = (mid + dt / t.mid) % 1;
      far = (far + dt / t.far) % 1;
      wheel = (wheel + dt / t.wheel) % 1;
      gust = (gust + dt / t.gust) % 1;
    }
    notifyListeners();
  }
}

class _SceneTiming {
  const _SceneTiming({
    required this.stopped,
    required this.road,
    required this.poles,
    required this.mid,
    required this.far,
    required this.wheel,
    required this.gust,
    required this.bob,
  });

  final bool stopped;
  final double road;
  final double poles;
  final double mid;
  final double far;
  final double wheel;
  final double gust;
  final double bob;
}

// ─── Paleta por hora del día ────────────────────────────────────────────────

class _ScenePalette {
  const _ScenePalette({
    required this.sky,
    required this.farHill,
    required this.bush,
    required this.pole,
    required this.window,
    required this.sceneText,
    required this.headlights,
    required this.stars,
  });

  factory _ScenePalette.forHour(double hour) {
    final night = hour < 6.5 || hour >= 19.5;
    final dusk = !night && (hour >= 17.5 || hour < 7.5);

    return _ScenePalette(
      sky: night
          ? const Color(0xFF444141)
          : dusk
              ? const Color(0xFFD7D3D3)
              : const Color(0xFFEAE9E9),
      farHill: night
          ? const Color(0xFF605D5D)
          : dusk
              ? const Color(0xFFC6C2C2)
              : const Color(0xFFD7D3D3),
      bush: night ? const Color(0xFF7D7979) : const Color(0xFFBAB6B6),
      pole: night ? const Color(0xFF9B9797) : const Color(0xFFBAB6B6),
      window: night ? const Color(0xFF605D5D) : const Color(0xFFF3F2F2),
      sceneText: night ? const Color(0xFFD7D3D3) : const Color(0xFF605D5D),
      headlights: night || dusk,
      stars: night,
    );
  }

  final Color sky;
  final Color farHill;
  final Color bush;
  final Color pole;
  final Color window;
  final Color sceneText;
  final bool headlights;
  final bool stars;
}

// ─── Painter ────────────────────────────────────────────────────────────────

/// Constantes de geometría del export. Los porcentajes son de la altura del
/// contenedor; los píxeles son absolutos igual que en el CSS.
const double _groundTop = 0.56; // suelo: bottom 0, height 44%
const double _farHillH = 0.34; // cerros: height 34%
const double _bushH = 26;
const double _poleH = 52;
const double _roadDashBottom = 0.16;
const double _tileVb = 206; // ancho del viewBox de las capas de parallax

const double _truckW = 156; // 106 (caja) + 4 (gap) + 46 (cabina)
const double _truckH = 58;

class _TruckScenePainter extends CustomPainter {
  _TruckScenePainter({
    required this.clock,
    required this.palette,
    required this.mechanical,
    required this.stopped,
    required this.gusting,
    required this.gustOpacity,
    required this.progress,
  }) : super(repaint: clock);

  final _SceneClock clock;
  final _ScenePalette palette;
  final MechanicalState mechanical;
  final bool stopped;
  final bool gusting;
  final double gustOpacity;

  /// Avance del viaje 0–1.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ground = h * _groundTop;

    canvas.drawRect(Offset.zero & size, Paint()..color = palette.sky);
    if (palette.stars) _paintStars(canvas, w, h);

    _paintFarHills(canvas, w, h, ground);
    _paintBushes(canvas, w, ground);
    _paintPoles(canvas, w, ground);

    // Suelo, por encima de las capas para recortarlas contra el horizonte.
    canvas
      ..drawRect(
        Rect.fromLTRB(0, ground, w, h),
        Paint()..color = const Color(0xFF605D5D),
      )
      ..drawRect(
        Rect.fromLTWH(0, ground, w, 2),
        Paint()..color = const Color(0xFFF3F2F2).withValues(alpha: 0.4),
      );

    _paintRoadDashes(canvas, w, h);
    if (gusting) _paintGusts(canvas, w, h);
    _paintTruck(canvas, w, ground);
  }

  // ── Capas de fondo ──

  void _paintStars(Canvas canvas, double w, double h) {
    // viewBox 0 0 412 90 estirado a 100% × 52% (preserveAspectRatio none).
    const coords = <(double, double, int)>[
      (38, 14, 0xFFD7D3D3),
      (96, 30, 0xFFBAB6B6),
      (148, 10, 0xFFD7D3D3),
      (214, 24, 0xFFBAB6B6),
      (268, 8, 0xFFD7D3D3),
      (322, 28, 0xFFBAB6B6),
      (376, 16, 0xFFD7D3D3),
    ];
    final sx = w / 412;
    final sy = h * 0.52 / 90;
    for (final (x, y, color) in coords) {
      canvas.drawRect(
        Rect.fromLTWH(x * sx, y * sy, 2 * sx, 2 * sy),
        Paint()..color = Color(color),
      );
    }
  }

  /// Dibuja una capa de parallax repitiendo su patrón cada `w` píxeles, que es
  /// justo lo que recorre la animación `slideRoad` del CSS (-33.33% de un
  /// elemento con 300% de ancho). Por eso el ciclo es perfectamente continuo.
  void _tile(
    Canvas canvas,
    double w,
    double phase,
    void Function(Canvas canvas) drawCopy,
  ) {
    final shift = -phase * w;
    for (var i = 0; i < 2; i++) {
      canvas
        ..save()
        ..translate(shift + i * w, 0);
      drawCopy(canvas);
      canvas.restore();
    }
  }

  void _paintFarHills(Canvas canvas, double w, double h, double ground) {
    final layerH = h * _farHillH;
    final top = ground - layerH;
    final sx = w / _tileVb;
    final sy = layerH / 60;
    final paint = Paint()..color = palette.farHill;

    const tris = <List<(double, double)>>[
      [(0, 60), (38, 18), (74, 60)],
      [(66, 60), (122, 6), (178, 60)],
      [(164, 60), (194, 26), (206, 60)],
    ];

    _tile(canvas, w, clock.far, (c) {
      for (final tri in tris) {
        c.drawPath(_polygon(tri, sx, sy, top), paint);
      }
    });
  }

  void _paintBushes(Canvas canvas, double w, double ground) {
    final top = ground - _bushH;
    final sx = w / _tileVb;
    const sy = _bushH / 26;
    final paint = Paint()..color = palette.bush;

    const tris = <List<(double, double)>>[
      [(12, 26), (22, 10), (32, 26)],
      [(70, 26), (82, 6), (94, 26)],
      [(140, 26), (150, 12), (160, 26)],
      [(182, 26), (192, 8), (202, 26)],
    ];

    _tile(canvas, w, clock.mid, (c) {
      for (final tri in tris) {
        c.drawPath(_polygon(tri, sx, sy, top), paint);
      }
    });
  }

  void _paintPoles(Canvas canvas, double w, double ground) {
    final top = ground - _poleH;
    final sx = w / _tileVb;
    const sy = _poleH / 52;
    final paint = Paint()..color = palette.pole;

    _tile(canvas, w, clock.poles, (c) {
      for (final x in const [30.0, 132.0]) {
        // Mástil y brazo, como los dos <rect> del SVG.
        c
          ..drawRect(
            Rect.fromLTWH(x * sx, 4 * sy + top, 2.5 * sx, 48 * sy),
            paint,
          )
          ..drawRect(
            Rect.fromLTWH(x * sx, 4 * sy + top, 16 * sx, 2.5 * sy),
            paint,
          );
      }
    });
  }

  void _paintRoadDashes(Canvas canvas, double w, double h) {
    // repeating-linear-gradient(to right, #f3f2f2 0 28px, transparent 28 62px)
    const dash = 28.0;
    const period = 62.0;
    final y = h * (1 - _roadDashBottom) - 4;
    final paint = Paint()..color = const Color(0xFFF3F2F2);

    // La franja recorre `w` px por ciclo igual que el CSS, pero el mosaico se
    // ancla al periodo del patrón para que no salte al reiniciar la fase.
    var x = -((clock.road * w) % period) - period;
    while (x < w) {
      canvas.drawRect(Rect.fromLTWH(x, y, dash, 4), paint);
      x += period;
    }
  }

  void _paintGusts(Canvas canvas, double w, double h) {
    // Líneas horizontales cada 19 px recortadas en bandas de 44 px cada 128.
    const bandW = 44.0;
    const bandPeriod = 128.0;
    const lineGap = 19.0;
    const boxH = 60.0;
    final top = h * (1 - 0.46) - boxH;
    final paint = Paint()
      ..color = palette.sceneText.withValues(alpha: gustOpacity);

    var x = -((clock.gust * w) % bandPeriod) - bandPeriod;
    while (x < w) {
      for (var y = 0.0; y < boxH; y += lineGap) {
        canvas.drawRect(Rect.fromLTWH(x, top + y, bandW, 1.5), paint);
      }
      x += bandPeriod;
    }
  }

  // ── Tracto ──

  void _paintTruck(Canvas canvas, double w, double ground) {
    // left: 22%..76% del ancho, y translateX(-50%) sobre 156 px de tracto.
    final left = w * _truckLeftFraction - _truckW / 2;

    _paintShadow(canvas, left, ground);

    canvas.save();
    _applyBodyMotion(canvas, left, ground);

    final top = ground - _truckH;
    _paintTrailer(canvas, left, ground);
    _paintCab(canvas, left, top, ground);
    _paintWheels(canvas, left, ground);

    if (palette.headlights) _paintHeadlights(canvas, left, ground);
    if (mechanical == MechanicalState.crashed) _paintSmoke(canvas, left, top);
    if (stopped && mechanical != MechanicalState.crashed) {
      _paintZzz(canvas, left, top);
    }
    canvas.restore();
  }

  double get _truckLeftFraction => 0.22 + progress * 0.54;

  void _applyBodyMotion(Canvas canvas, double left, double ground) {
    final t = clock.bob;
    if (mechanical == MechanicalState.flatTire) {
      // limp: cojea girando sobre el eje trasero (70% 100% del cuerpo).
      final deg = _keyframes(t, const [(0, 0), (0.25, -1.1), (0.6, 0.5)]);
      canvas
        ..translate(left + _truckW * 0.7, ground)
        ..rotate(deg * math.pi / 180)
        ..translate(-(left + _truckW * 0.7), -ground);
      return;
    }

    final dy = stopped
        ? _keyframes(t, const [(0, 0), (0.5, -1)])
        : _keyframes(t, const [(0, 0), (0.3, -1.5), (0.65, 1)]);
    canvas.translate(0, dy);
  }

  void _paintShadow(Canvas canvas, double left, double ground) {
    canvas.drawRect(
      Rect.fromLTWH(left, ground + 9, 148, 7),
      Paint()..color = const Color(0xFF201E1D).withValues(alpha: 0.3),
    );
  }

  void _paintTrailer(Canvas canvas, double left, double ground) {
    final box = Rect.fromLTWH(left, ground - 46, 106, 46);
    canvas
      ..drawRect(box, Paint()..color = const Color(0xFFC80000))
      // box-sizing: border-box → el borde de 2 px va por dentro.
      ..drawRect(
        box.deflate(1),
        Paint()
          ..color = const Color(0xFF201E1D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  void _paintCab(Canvas canvas, double left, double top, double ground) {
    final x = left + 110;
    final ink = Paint()..color = const Color(0xFF201E1D);
    canvas
      ..drawRect(Rect.fromLTWH(x, top, 46, 58), ink)
      ..drawRect(
        Rect.fromLTWH(x + 6, top + 7, 24, 16),
        Paint()..color = palette.window,
      )
      // Espejo: sobresale 4 px del costado derecho de la cabina.
      ..drawRect(Rect.fromLTWH(x + 44, ground - 14, 6, 8), ink);
  }

  void _paintWheels(Canvas canvas, double left, double ground) {
    final angle = clock.wheel * 2 * math.pi;
    final flat = mechanical == MechanicalState.flatTire;

    for (final (dx, isFront) in const [
      (14.0, false),
      (42.0, false),
      (124.0, true),
    ]) {
      final center = Offset(left + dx + 10, ground);
      final color = isFront && flat
          ? const Color(0xFF7D7979)
          : const Color(0xFF201E1D);

      canvas
        ..drawCircle(center, 10, Paint()..color = color)
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(angle)
        // El punto del rin va centrado igual que en el export, así que el giro
        // no se percibe. Se mantiene por paridad — ver pendientes.
        ..drawCircle(
          Offset.zero,
          2,
          Paint()..color = const Color(0xFFBAB6B6),
        )
        ..restore();
    }
  }

  void _paintHeadlights(Canvas canvas, double left, double ground) {
    final x = left + 154;
    final top = ground - 42;
    final path = Path()
      ..moveTo(x, top + 10)
      ..lineTo(x + 90, top)
      ..lineTo(x + 90, top + 34)
      ..lineTo(x, top + 20)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFF8F4F4).withValues(alpha: 0.32),
    );
  }

  void _paintSmoke(Canvas canvas, double left, double top) {
    const puffs = <(double, double, double)>[
      (139, 7, 0),
      (125.5, 5.5, 0.375),
    ];
    for (final (dx, r, delay) in puffs) {
      final t = (clock.smoke + delay) % 1;
      final paint = Paint()
        ..color = const Color(0xFF7D7979)
            .withValues(alpha: (0.55 * (1 - t)).clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(left + dx, top - 18 + r - 26 * t),
        r * (0.7 + 0.8 * t),
        paint,
      );
    }
  }

  void _paintZzz(Canvas canvas, double left, double top) {
    TextPainter(
      text: TextSpan(
        text: 'Z z z',
        style: TextStyle(
          fontFamily: 'Archivo',
          fontSize: 15,
          fontWeight: FontWeight.w900,
          fontVariations: const [FontVariation('wght', 900)],
          letterSpacing: 1.5,
          color: palette.sceneText,
        ),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, Offset(left + 120, top - 24));
  }

  // ── Utilidades ──

  Path _polygon(
    List<(double, double)> pts,
    double sx,
    double sy,
    double top,
  ) {
    final path = Path()..moveTo(pts.first.$1 * sx, pts.first.$2 * sy + top);
    for (final p in pts.skip(1)) {
      path.lineTo(p.$1 * sx, p.$2 * sy + top);
    }
    return path..close();
  }

  /// Interpola keyframes CSS `(posición 0–1, valor)` en bucle cerrado: el
  /// último tramo vuelve al valor del primero, como hace `100% { … }`.
  double _keyframes(double t, List<(double, double)> frames) {
    for (var i = 0; i < frames.length; i++) {
      final (at, value) = frames[i];
      final isLast = i == frames.length - 1;
      final (nextAt, nextValue) =
          isLast ? (1.0, frames.first.$2) : frames[i + 1];
      if (t >= at && t <= nextAt) {
        final span = nextAt - at;
        final k = span == 0 ? 0.0 : (t - at) / span;
        // ease-in-out, que es el timing de todos los keyframes del export.
        final eased = k < 0.5
            ? 2 * k * k
            : 1 - math.pow(-2 * k + 2, 2).toDouble() / 2;
        return value + (nextValue - value) * eased;
      }
    }
    return frames.first.$2;
  }

  @override
  bool shouldRepaint(_TruckScenePainter old) =>
      old.palette.sky != palette.sky ||
      old.mechanical != mechanical ||
      old.stopped != stopped ||
      old.gusting != gusting ||
      old.gustOpacity != gustOpacity ||
      old.progress != progress;
}
