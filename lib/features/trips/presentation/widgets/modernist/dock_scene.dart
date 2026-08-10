import 'package:flutter/material.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';

/// El almacén con el tracto estacionado, del export «Inicio Sin Viaje».
///
/// Es la contraparte de `TruckScene`: allá el tracto va en marcha y todo se
/// mueve; aquí está esperando asignación y solo respira. Las cifras del mes no
/// van en tarjetas — están estarcidas en las cajas y colgando de las vigas.
///
/// Las medidas del export son píxeles absolutos contra los bordes de la escena
/// (`top:212px`, `bottom:170px`, …), así que se respetan tal cual y solo el
/// alto disponible varía según el dispositivo.
class DockScene extends StatelessWidget {
  const DockScene({
    required this.level,
    required this.tripsMonth,
    required this.kmMonth,
    required this.pointsMonth,
    required this.streak,
    super.key,
  });

  final OperatorLevel level;
  final String tripsMonth;
  final String kmMonth;
  final String pointsMonth;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final dock = _DockPalette.of(palette);

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DockPainter(dock)),
          ),
          _HangingSigns(
            dock: dock,
            palette: palette,
            streak: streak,
            pointsMonth: pointsMonth,
          ),
          _LevelPlate(dock: dock, level: level),
          _CrateStack(dock: dock, kmMonth: kmMonth, tripsMonth: tripsMonth),
          // Caja metálica suelta del lado derecho.
          Positioned(
            right: 10,
            bottom: 170,
            child: Container(width: 42, height: 26, color: dock.metal),
          ),
          _ParkedTruck(dock: dock),
          _SwipeHint(palette: palette),
        ],
      ),
    );
  }
}

// ─── Paleta propia de la escena ─────────────────────────────────────────────

/// Colores que solo existen en el almacén. Viven aquí y no en
/// [ModernistPalette] porque ningún otro export los usa.
///
/// Ojo con dos que **no** se invierten en oscuro: la placa de nivel conserva
/// borde y texto en `#201e1d`, y las cajas conservan sus franjas `#6B3E1E`.
/// Son objetos físicos de la escena, no superficies de la interfaz.
class _DockPalette {
  const _DockPalette({
    required this.bannerBg,
    required this.wall,
    required this.line,
    required this.pillar,
    required this.metal,
    required this.floor,
    required this.floorMark,
    required this.plateBg,
    required this.plateScrew,
    required this.plateKicker,
    required this.crateBase,
    required this.crateLabelled,
    required this.truckShadow,
    required this.cabWindow,
    required this.crateWidthBottom,
  });

  static _DockPalette of(ModernistPalette palette) =>
      palette.isDark ? _dockDark : _dockLight;

  /// Tinta física: la placa de nivel y el contorno de las cajas siguen en este
  /// color aunque el tema sea oscuro.
  static const objectInk = Color(0xFF201E1D);

  /// Franja de las cajas de cartón, igual en los dos temas.
  static const crateStripe = Color(0xFF6B3E1E);

  /// Estarcido sobre las cajas: relleno claro perfilado en [objectInk].
  static const crateStencil = Color(0xFFF8F4F4);

  /// Luces del techo sobre la barra del andén.
  static const dockLight = Color(0xFFFFE9A8);

  /// Rótulo de ubicación en la barra del andén: claro en los dos temas, porque
  /// la barra siempre es un gris oscuro.
  static const bannerText = Color(0xFFF3F2F2);

  final Color bannerBg;
  final Color wall;
  final Color line;
  final Color pillar;
  final Color metal;
  final Color floor;
  final Color floorMark;
  final Color plateBg;
  final Color plateScrew;
  final Color plateKicker;
  final Color crateBase;
  final Color crateLabelled;
  final Color truckShadow;
  final Color cabWindow;

  /// La caja de abajo mide distinto en cada export (97 px en claro, 86 en
  /// oscuro). Se respeta cada uno para no desviarse de su mockup.
  final double crateWidthBottom;
}

// Las dos instancias viven fuera de la clase a propósito: como constantes
// estáticas dentro de una clase privada, el analizador pide convertirla en
// enum, y un enum no admite este puñado de campos de color.
const _dockLight = _DockPalette(
  bannerBg: Color(0xFF444141),
  wall: Color(0xFFD7D3D3),
  line: Color(0xFFBAB6B6),
  pillar: Color(0xFFCFCBCB),
  metal: Color(0xFF807C7C),
  floor: Color(0xFF9B9797),
  floorMark: Color(0xFF201E1D),
  plateBg: Color(0xFFF3F2F2),
  plateScrew: Color(0xFF7D7979),
  plateKicker: Color(0xFF7D7979),
  crateBase: Color(0xFFC8875A),
  crateLabelled: Color(0xFFC8875A),
  truckShadow: Color(0x47201E1D), // #201e1d @ .28
  cabWindow: Color(0xFFF3F2F2),
  crateWidthBottom: 97,
);

const _dockDark = _DockPalette(
  bannerBg: Color(0xFF565353),
  wall: Color(0xFF565353),
  line: Color(0xFF807C7C),
  pillar: Color(0xFF4A4747),
  metal: Color(0xFF8E8A8A),
  floor: Color(0xFF6E6A6A),
  floorMark: Color(0xFFF3F2F2),
  plateBg: Color(0xFFD7D3D3),
  plateScrew: Color(0xFF9B9797),
  plateKicker: Color(0xFF444141),
  crateBase: Color(0xFF4D170E),
  crateLabelled: Color(0xFF471D16),
  truckShadow: Color(0x52000000), // negro @ .32
  cabWindow: Color(0xFFD7D3D3),
  crateWidthBottom: 86,
);

/// Alto del piso, medido desde abajo. Casi todo se ancla a esta línea.
const double _floorH = 170;

// ─── Arquitectura ───────────────────────────────────────────────────────────

class _DockPainter extends CustomPainter {
  _DockPainter(this.dock);

  final _DockPalette dock;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floorTop = h - _floorH;

    // Pared del fondo, hasta la línea del piso.
    canvas.drawRect(
      Rect.fromLTRB(0, 0, w, floorTop),
      Paint()..color = dock.wall,
    );

    _paintZigzag(canvas, w);

    // Columnas laterales.
    final pillar = Paint()..color = dock.pillar;
    canvas
      ..drawRect(Rect.fromLTWH(26, 0, 10, floorTop), pillar)
      ..drawRect(Rect.fromLTWH(w - 36, 0, 10, floorTop), pillar);

    _paintShutter(canvas, w, floorTop);

    // Piso, y la regla que lo separa de la pared. Esa regla se queda en tinta
    // física en los dos temas: es una línea pintada en el suelo.
    canvas
      ..drawRect(Rect.fromLTRB(0, floorTop, w, h), Paint()..color = dock.floor)
      ..drawRect(
        Rect.fromLTWH(0, floorTop - 2, w, 2),
        Paint()..color = _DockPalette.objectInk,
      );

    _paintFloorMarks(canvas, w, h, floorTop);
  }

  /// Diente de sierra del techo: viewBox 0 0 412 26 estirado al ancho.
  void _paintZigzag(Canvas canvas, double w) {
    const vbW = 412.0;
    final sx = w / vbW;
    final path = Path()..moveTo(0, 0);
    // Vértices cada 34 px del viewBox, alternando 24 y 0.
    for (var i = 1; i * 34 <= vbW; i++) {
      path.lineTo(i * 34 * sx, i.isOdd ? 24 : 0);
    }
    path.lineTo(vbW * sx, 0);

    canvas.drawPath(
      path,
      Paint()
        ..color = dock.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  /// Cortina metálica del andén: fondo con listones horizontales y su cabezal.
  void _paintShutter(Canvas canvas, double w, double floorTop) {
    final rect = Rect.fromLTRB(62, 212, w - 62, floorTop);
    if (rect.height <= 0) return;

    canvas
      ..save()
      ..clipRect(rect)
      ..drawRect(rect, Paint()..color = dock.pillar);

    // repeating-linear-gradient(to bottom, transparent 0 11px, línea 11 13px)
    final slat = Paint()..color = dock.line;
    for (var y = rect.top + 11; y < rect.bottom; y += 13) {
      canvas.drawRect(Rect.fromLTRB(rect.left, y, rect.right, y + 2), slat);
    }

    canvas
      ..restore()
      // Cabezal de 3 px que remata la cortina por arriba.
      ..drawRect(
        Rect.fromLTWH(62, 212, w - 124, 3),
        Paint()..color = _DockPalette.objectInk,
      );
  }

  /// Las dos diagonales pintadas en el piso que delimitan el cajón de carga.
  void _paintFloorMarks(Canvas canvas, double w, double h, double floorTop) {
    const vbW = 412.0;
    final sx = w / vbW;
    final paint = Paint()
      ..color = dock.floorMark.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas
      ..drawLine(Offset(128 * sx, floorTop), Offset(62 * sx, h), paint)
      ..drawLine(Offset(284 * sx, floorTop), Offset(350 * sx, h), paint);
  }

  @override
  bool shouldRepaint(_DockPainter old) => old.dock.wall != dock.wall;
}

// ─── Letreros colgados ──────────────────────────────────────────────────────

class _HangingSigns extends StatelessWidget {
  const _HangingSigns({
    required this.dock,
    required this.palette,
    required this.streak,
    required this.pointsMonth,
  });

  final _DockPalette dock;
  final ModernistPalette palette;
  final int streak;
  final String pointsMonth;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 14,
      top: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Sign(
            dock: dock,
            label: 'RACHA',
            value: '${streak}d',
            cable: 52,
            background: palette.bg,
            foreground: palette.ink,
            // swayA: −0.7° ↔ 0.7°
            from: -0.7,
            to: 0.7,
            period: const Duration(milliseconds: 5200),
          ),
          const SizedBox(width: 10),
          _Sign(
            dock: dock,
            label: 'PUNTOS',
            value: '+$pointsMonth',
            cable: 28,
            background: palette.positive,
            foreground: palette.onPositive,
            // swayB: 0.5° ↔ −0.9°
            from: 0.5,
            to: -0.9,
            period: const Duration(milliseconds: 4900),
          ),
        ],
      ),
    );
  }
}

class _Sign extends StatefulWidget {
  const _Sign({
    required this.dock,
    required this.label,
    required this.value,
    required this.cable,
    required this.background,
    required this.foreground,
    required this.from,
    required this.to,
    required this.period,
  });

  final _DockPalette dock;
  final String label;
  final String value;
  final double cable;
  final Color background;
  final Color foreground;
  final double from;
  final double to;
  final Duration period;

  @override
  State<_Sign> createState() => _SignState();
}

class _SignState extends State<_Sign> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeInOut);

    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final deg = widget.from + (widget.to - widget.from) * curve.value;
        return Transform.rotate(
          angle: deg * 3.1415926535 / 180,
          // Gira colgando del techo, no desde su propio centro.
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 2, height: widget.cable, color: widget.dock.metal),
          Container(
            constraints: const BoxConstraints(minWidth: 62),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: widget.background,
              border: Border.all(
                color: _DockPalette.objectInk,
                width: ModernistRule.base,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: 0.8,
                  child: Text(
                    widget.label,
                    style: ModernistType.of(
                      size: 10,
                      weight: 800,
                      color: widget.foreground,
                      tracking: 0.08,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.value,
                  style: ModernistType.of(
                    size: 19,
                    weight: 900,
                    color: widget.foreground,
                    tracking: -0.02,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Placa de nivel ─────────────────────────────────────────────────────────

class _LevelPlate extends StatelessWidget {
  const _LevelPlate({required this.dock, required this.level});

  final _DockPalette dock;
  final OperatorLevel level;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 232,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 124,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: dock.plateBg,
                  border: Border.all(
                    color: _DockPalette.objectInk,
                    width: ModernistRule.base,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: ModernistColors.level(level),
                        border: Border.all(color: _DockPalette.objectInk),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NIVEL',
                          style: ModernistType.of(
                            size: 10,
                            weight: 800,
                            color: dock.plateKicker,
                            tracking: 0.1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          level.displayName.toUpperCase(),
                          style: ModernistType.of(
                            size: 16,
                            weight: 900,
                            color: _DockPalette.objectInk,
                            tracking: 0.02,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Los dos tornillos de la esquina superior.
              for (final left in [true, false])
                Positioned(
                  top: 5,
                  left: left ? 5 : null,
                  right: left ? null : 5,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dock.plateScrew,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Torre de cajas ─────────────────────────────────────────────────────────

class _CrateStack extends StatelessWidget {
  const _CrateStack({
    required this.dock,
    required this.kmMonth,
    required this.tripsMonth,
  });

  final _DockPalette dock;
  final String kmMonth;
  final String tripsMonth;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      bottom: _floorH,
      // Sin ancho fijo: la caja de abajo es más ancha que la columna de 94 px
      // del export y sobresale a la derecha, igual que en el HTML.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        // El export apila con `column-reverse`: el primer hijo queda abajo.
        children: [
          _Crate(dock: dock, label: 'VIAJES', value: tripsMonth),
          _Crate(dock: dock, label: 'KM', value: kmMonth),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              width: dock.crateWidthBottom,
              height: 84,
              decoration: BoxDecoration(
                color: dock.crateBase,
                border: Border.all(
                  color: _DockPalette.objectInk,
                  width: ModernistRule.base,
                ),
              ),
              child: const _CrateStripes(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Crate extends StatelessWidget {
  const _Crate({
    required this.dock,
    required this.label,
    required this.value,
  });

  final _DockPalette dock;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 62,
      decoration: BoxDecoration(
        color: dock.crateLabelled,
        // Sin borde inferior: se apoya en la caja de abajo.
        border: const Border(
          top: BorderSide(
            color: _DockPalette.objectInk,
            width: ModernistRule.base,
          ),
          left: BorderSide(
            color: _DockPalette.objectInk,
            width: ModernistRule.base,
          ),
          right: BorderSide(
            color: _DockPalette.objectInk,
            width: ModernistRule.base,
          ),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _CrateStripes()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stencil(
                  text: label,
                  size: 10,
                  weight: 800,
                  tracking: 0.1,
                ),
                const SizedBox(height: 1),
                _Stencil(
                  text: value,
                  size: 21,
                  weight: 900,
                  tracking: -0.02,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Franjas horizontales del cartón corrugado.
///
/// El export las hace con `repeating-linear-gradient` de periodo fijo en
/// píxeles; un `LinearGradient` de Flutter reparte sus paradas sobre el alto
/// de la caja, así que el periodo cambiaría con el tamaño. Se pintan a mano.
class _CrateStripes extends StatelessWidget {
  const _CrateStripes();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _StripePainter(), size: Size.infinite);
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // transparente 0→15 px, franja 15→17 px, y vuelta a empezar.
    final paint = Paint()..color = _DockPalette.crateStripe;
    for (var y = 15.0; y < size.height; y += 17) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => false;
}

/// Texto estarcido: relleno claro con el contorno de la tinta física, igual
/// que `-webkit-text-stroke` con `paint-order: stroke fill`.
class _Stencil extends StatelessWidget {
  const _Stencil({
    required this.text,
    required this.size,
    required this.weight,
    required this.tracking,
  });

  final String text;
  final double size;
  final int weight;
  final double tracking;

  @override
  Widget build(BuildContext context) {
    final base = ModernistType.of(
      size: size,
      weight: weight,
      color: _DockPalette.crateStencil,
      tracking: tracking,
      height: 1,
    );

    return Stack(
      children: [
        Text(
          text,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              // -webkit-text-stroke centra el trazo: 0.6 px por lado.
              ..strokeWidth = 1.2
              ..color = _DockPalette.objectInk,
          ),
        ),
        Text(text, style: base),
      ],
    );
  }
}

// ─── Tracto estacionado ─────────────────────────────────────────────────────

class _ParkedTruck extends StatefulWidget {
  const _ParkedTruck({required this.dock});

  final _DockPalette dock;

  @override
  State<_ParkedTruck> createState() => _ParkedTruckState();
}

class _ParkedTruckState extends State<_ParkedTruck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Sombra en el piso, por debajo del tracto.
        Positioned(
          bottom: 156,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 310,
              height: 14,
              color: widget.dock.truckShadow,
            ),
          ),
        ),
        Positioned(
          bottom: _floorH,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.scale(
              scale: 1.55,
              alignment: Alignment.bottomCenter,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) => Transform.translate(
                  // idleBob: 0 → −1.5 px
                  offset: Offset(
                    0,
                    -1.5 * Curves.easeInOut.transform(_c.value),
                  ),
                  child: child,
                ),
                child: _TruckBody(dock: widget.dock),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TruckBody extends StatelessWidget {
  const _TruckBody({required this.dock});

  final _DockPalette dock;

  @override
  Widget build(BuildContext context) {
    const ink = _DockPalette.objectInk;

    return SizedBox(
      width: 199, // 136 (caja) + 5 (separación) + 58 (cabina)
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 136,
              height: 60,
              decoration: BoxDecoration(
                color: ModernistColors.red,
                border: Border.all(color: ink, width: ModernistRule.base),
              ),
            ),
          ),
          Positioned(
            left: 141,
            bottom: 0,
            child: SizedBox(
              width: 58,
              height: 76,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(child: ColoredBox(color: ink)),
                  Positioned(
                    top: 9,
                    left: 8,
                    child: Container(
                      width: 32,
                      height: 21,
                      color: dock.cabWindow,
                    ),
                  ),
                  // Espejo lateral, sobresale del costado.
                  const Positioned(
                    bottom: 8,
                    right: -5,
                    child: SizedBox(
                      width: 6,
                      height: 11,
                      child: ColoredBox(color: ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final left in const [18.0, 54.0, 158.0])
            Positioned(
              left: left,
              bottom: -13,
              child: const _Wheel(),
            ),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: _DockPalette.objectInk,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFBAB6B6),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Indicación de deslizar ─────────────────────────────────────────────────

class _SwipeHint extends StatefulWidget {
  const _SwipeHint({required this.palette});

  final ModernistPalette palette;

  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          // hintUp: sube 4 px y pasa de .55 a 1 de opacidad.
          final t = Curves.easeInOut.transform(_c.value);
          return Transform.translate(
            offset: Offset(0, -4 * t),
            child: Opacity(opacity: 0.55 + 0.45 * t, child: child),
          );
        },
        child: Center(
          child: Container(
            color: palette.ink,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '↑',
                  style: ModernistType.of(
                    size: 14,
                    weight: 900,
                    color: palette.onInk,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'DESLIZA PARA VER MÁS',
                  style: ModernistType.of(
                    size: 11,
                    weight: 800,
                    color: palette.onInk,
                    tracking: 0.12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra del andén que corona la sección: luces del techo y la ubicación.
class DockBanner extends StatelessWidget {
  const DockBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final dock = _DockPalette.of(palette);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: dock.bannerBg,
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 2; i++) ...[
            Container(width: 44, height: 7, color: _DockPalette.dockLight),
            const SizedBox(width: 10),
          ],
          const Spacer(),
          Text(
            'ALMACÉN · ANDÉN 3',
            style: modernistMono(
              size: 10,
              color: _DockPalette.bannerText,
            ),
          ),
        ],
      ),
    );
  }
}
