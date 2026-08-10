import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';

/// Un evento marcado sobre la ruta.
class RouteEvent {
  const RouteEvent({required this.at, required this.alert});

  /// Posición del evento dentro del viaje, de 0 (salida) a 1 (llegada).
  final double at;

  /// `true` para una alerta de seguridad (roja), `false` para una incidencia.
  final bool alert;
}

/// Mapa de la ruta recorrida, portado del SVG del export «Detalle Viaje».
///
/// Igual que `RouteMapIllustration`, **el trazo es fijo**: no corresponde a las
/// coordenadas del viaje. Lo que sí sale de datos reales son los marcadores de
/// eventos, que se reparten sobre la polilínea según el momento del viaje en
/// que ocurrieron. Ver pendientes en `docs/features/modernist-home.md`.
class GpsRouteIllustration extends StatelessWidget {
  const GpsRouteIllustration({
    required this.origen,
    required this.destino,
    required this.events,
    super.key,
  });

  final String origen;
  final String destino;
  final List<RouteEvent> events;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: _GpsRoutePainter(
          origen: origen.toUpperCase(),
          destino: destino.toUpperCase(),
          events: events,
          palette: ModernistPalette.of(context),
        ),
        size: Size.infinite,
      ),
    );
  }
}

const double _vbW = 412;
const double _vbH = 190;

/// La polilínea del export, en coordenadas del viewBox.
const _routePoints = <(double, double)>[
  (34, 162),
  (78, 152),
  (112, 138),
  (152, 132),
  (186, 118),
  (214, 96),
  (248, 84),
  (282, 66),
  (318, 54),
  (352, 42),
  (380, 30),
];

class _GpsRoutePainter extends CustomPainter {
  _GpsRoutePainter({
    required this.origen,
    required this.destino,
    required this.events,
    required this.palette,
  });

  final String origen;
  final String destino;
  final List<RouteEvent> events;
  final ModernistPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.mapBg);

    // preserveAspectRatio="xMidYMid slice" = BoxFit.cover.
    final scale = math.max(size.width / _vbW, size.height / _vbH);
    canvas
      ..save()
      ..translate(
        (size.width - _vbW * scale) / 2,
        (size.height - _vbH * scale) / 2,
      )
      ..scale(scale);

    _paintTerrain(canvas);
    _paintRoute(canvas);
    _paintEvents(canvas);
    _paintEndpoints(canvas);

    canvas.restore();
  }

  void _paintTerrain(Canvas canvas) {
    canvas
      ..drawPath(
        _poly(const [
          (0, 190), (0, 118), (88, 98), (176, 124),
          (248, 104), (336, 130), (412, 110), (412, 190),
        ]),
        Paint()..color = palette.mapHillFront,
      )
      ..drawPath(
        _poly(const [
          (0, 68), (96, 50), (190, 74),
          (268, 46), (412, 60), (412, 0), (0, 0),
        ]),
        Paint()..color = palette.mapHillBack,
      );

    final hair = Paint()
      ..color = palette.mapGrid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const lines = <((double, double), (double, double))>[
      ((0, 146), (412, 128)),
      ((62, 190), (102, 0)),
      ((276, 190), (252, 0)),
    ];
    for (final (a, b) in lines) {
      canvas.drawLine(Offset(a.$1, a.$2), Offset(b.$1, b.$2), hair);
    }
  }

  void _paintRoute(Canvas canvas) {
    canvas.drawPath(
      _routePath(),
      Paint()
        ..color = palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Cuadros de 15 px centrados sobre la ruta, perfilados con el fondo para
  /// que se despeguen del trazo.
  void _paintEvents(Canvas canvas) {
    final metric = _routePath().computeMetrics().first;

    for (final event in events) {
      final at = metric.getTangentForOffset(
        metric.length * event.at.clamp(0.0, 1.0),
      );
      if (at == null) continue;

      final rect = Rect.fromCenter(center: at.position, width: 15, height: 15);
      canvas
        ..drawRect(
          rect,
          Paint()
            ..color = event.alert ? ModernistColors.red : palette.neutralMark,
        )
        // El perfil es el fondo de la pantalla, no el del mapa: así el
        // marcador se despega del trazo negro sin ensuciarse con el terreno.
        ..drawRect(
          rect,
          Paint()
            ..color = palette.bg
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
    }
  }

  void _paintEndpoints(Canvas canvas) {
    final ink = Paint()..color = palette.ink;
    canvas
      ..drawRect(const Rect.fromLTWH(27, 155, 14, 14), ink)
      ..drawRect(
        const Rect.fromLTWH(373, 23, 14, 14),
        Paint()
          ..color = palette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

    _label(canvas, origen, const Offset(48, 178), anchorEnd: false);
    _label(canvas, destino, const Offset(368, 18), anchorEnd: true);
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    required bool anchorEnd,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: ModernistType.of(
          size: 11,
          weight: 800,
          color: palette.ink,
          // letter-spacing 1.4 en unidades del viewBox, a 11 px de tipo.
          tracking: 1.4 / 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final baseline =
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.paint(
      canvas,
      Offset(anchorEnd ? at.dx - painter.width : at.dx, at.dy - baseline),
    );
  }

  Path _routePath() {
    final path = Path()
      ..moveTo(_routePoints.first.$1, _routePoints.first.$2);
    for (final p in _routePoints.skip(1)) {
      path.lineTo(p.$1, p.$2);
    }
    return path;
  }

  Path _poly(List<(double, double)> pts) {
    final path = Path()..moveTo(pts.first.$1, pts.first.$2);
    for (final p in pts.skip(1)) {
      path.lineTo(p.$1, p.$2);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_GpsRoutePainter old) =>
      old.palette.isDark != palette.isDark ||
      old.origen != origen ||
      old.destino != destino ||
      old.events.length != events.length;
}
