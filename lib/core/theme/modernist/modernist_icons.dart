/// Íconos del sistema Modernist, dibujados en vez de tipografiados.
///
/// Archivo no trae glifos de símbolo y los de Material desentonan con el
/// lenguaje plano y geométrico del sistema — además de no resolverse en los
/// goldens. Se pintan a mano, como los triángulos del ranking.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Engrane de ocho dientes rectos.
class ModernistGear extends StatelessWidget {
  const ModernistGear({required this.color, this.size = 20, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GearPainter(color: color),
    );
  }
}

class _GearPainter extends CustomPainter {
  const _GearPainter({required this.color});

  final Color color;

  static const _teeth = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final body = outer * 0.68;
    final paint = Paint()..color = color;

    // Dientes: rectángulos radiales, con las esquinas rectas del sistema.
    final tooth = Rect.fromCenter(
      center: Offset(0, -(body + outer) / 2),
      width: outer * 0.30,
      height: outer - body + outer * 0.24,
    );
    for (var i = 0; i < _teeth; i++) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(i * 2 * math.pi / _teeth)
        ..drawRect(tooth, paint)
        ..restore();
    }

    // Cuerpo con el hueco central.
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: center, radius: body)),
        Path()..addOval(Rect.fromCircle(center: center, radius: body * 0.42)),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GearPainter old) => old.color != color;
}
