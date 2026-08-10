import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';

/// Mapa ilustrado de la ruta, portado del SVG del export.
///
/// **No es un mapa real**: el trazo, los cerros y los marcadores son fijos y no
/// corresponden a las coordenadas del viaje. Lo único que responde a datos
/// reales es [progress], que avanza la línea negra y el punto rojo.
///
/// Es deliberado y temporal — ver pendientes en
/// `docs/features/modernist-home.md`. Cuando se dibuje la ruta con los puntos
/// GPS reales, este widget se reemplaza conservando el mismo lenguaje visual.
class RouteMapIllustration extends StatelessWidget {
  const RouteMapIllustration({
    required this.origen,
    required this.destino,
    required this.progress,
    super.key,
  });

  final String origen;
  final String destino;

  /// Avance del viaje 0–1.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: _RouteMapPainter(
          origen: origen.toUpperCase(),
          destino: destino.toUpperCase(),
          progress: progress.clamp(0.0, 1.0),
          palette: ModernistPalette.of(context),
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// El SVG original: viewBox 0 0 412 180, preserveAspectRatio "xMidYMid slice"
/// (equivalente a `BoxFit.cover`).
const double _vbW = 412;
const double _vbH = 180;

class _RouteMapPainter extends CustomPainter {
  _RouteMapPainter({
    required this.origen,
    required this.destino,
    required this.progress,
    required this.palette,
  });

  final String origen;
  final String destino;
  final double progress;
  final ModernistPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.mapBg);

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
    _paintMarkers(canvas);

    canvas.restore();
  }

  void _paintTerrain(Canvas canvas) {
    // Cerros del primer plano y del fondo.
    canvas
      ..drawPath(
        _poly(const [
          (0, 180), (0, 108), (84, 90), (168, 114),
          (240, 96), (330, 120), (412, 102), (412, 180),
        ]),
        Paint()..color = palette.mapHillFront,
      )
      ..drawPath(
        _poly(const [
          (0, 64), (96, 46), (190, 70),
          (268, 42), (412, 56), (412, 0), (0, 0),
        ]),
        Paint()..color = palette.mapHillBack,
      );

    // Cuatro líneas de terreno que cruzan el encuadre.
    final hair = Paint()
      ..color = palette.mapGrid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const lines = <((double, double), (double, double))>[
      ((0, 138), (412, 122)),
      ((58, 180), (96, 0)),
      ((268, 180), (246, 0)),
      ((0, 76), (412, 92)),
    ];
    for (final (a, b) in lines) {
      canvas.drawLine(Offset(a.$1, a.$2), Offset(b.$1, b.$2), hair);
    }
  }

  void _paintRoute(Canvas canvas) {
    final route = _routePath();
    final metric = route.computeMetrics().first;
    final total = metric.length;

    // Base punteada. El SVG usa pathLength="100", así que "9 7" son 9% y 7%
    // de la longitud real.
    final dashed = Path();
    var at = 0.0;
    while (at < total) {
      final end = math.min(at + total * 0.09, total);
      dashed.addPath(metric.extractPath(at, end), Offset.zero);
      at = end + total * 0.07;
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = palette.routePending
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Tramo recorrido.
    if (progress > 0) {
      canvas.drawPath(
        metric.extractPath(0, total * progress),
        Paint()
          ..color = palette.routeDone
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    }

    // Posición actual: el punto rojo con halo. En el SVG son dos trazos de
    // longitud 0.1 con `stroke-linecap: round`, o sea dos círculos.
    final head = metric.getTangentForOffset(total * progress)?.position;
    if (head != null) {
      canvas
        ..drawCircle(head, 9, Paint()..color = palette.routeHalo)
        ..drawCircle(head, 6, Paint()..color = ModernistColors.red);
    }
  }

  void _paintMarkers(Canvas canvas) {
    final ink = Paint()..color = palette.ink;
    canvas
      // Origen: cuadro sólido.
      ..drawRect(const Rect.fromLTWH(27, 145, 14, 14), ink)
      // Destino: cuadro hueco.
      ..drawRect(
        const Rect.fromLTWH(365, 33, 14, 14),
        Paint()
          ..color = palette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

    _label(canvas, origen, const Offset(48, 167), anchorEnd: false);
    _label(canvas, destino, const Offset(356, 26), anchorEnd: true);
  }

  /// Etiqueta del SVG. En SVG la `y` de un `<text>` es la línea base, no el
  /// borde superior, así que hay que descontar el ascenso.
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
          size: 12,
          weight: 800,
          color: palette.ink,
          // El SVG declara letter-spacing 1.6 en unidades del viewBox, que a
          // 12 px de tipo son 0.1333 em.
          tracking: 1.6 / 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final baseline =
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final dx = anchorEnd ? at.dx - painter.width : at.dx;
    painter.paint(canvas, Offset(dx, at.dy - baseline));
  }

  /// `M34 152 C 96 148, 122 124, 170 114 S 248 94, 292 66 S 344 48, 372 40`,
  /// con las curvas `S` expandidas: su primer control es el reflejo del
  /// segundo control anterior respecto al punto actual.
  Path _routePath() => Path()
    ..moveTo(34, 152)
    ..cubicTo(96, 148, 122, 124, 170, 114)
    ..cubicTo(218, 104, 248, 94, 292, 66)
    ..cubicTo(336, 38, 344, 48, 372, 40);

  Path _poly(List<(double, double)> pts) {
    final path = Path()..moveTo(pts.first.$1, pts.first.$2);
    for (final p in pts.skip(1)) {
      path.lineTo(p.$1, p.$2);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_RouteMapPainter old) =>
      old.progress != progress ||
      old.origen != origen ||
      old.destino != destino ||
      old.palette.isDark != palette.isDark;
}
