import 'package:flutter/material.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';

/// Color de marca del nivel. Única fuente: la usan el badge, el chip del
/// ranking y la barra del resumen de regreso.
Color levelColor(OperatorLevel level) => LevelBadge._levelAssets(level).$1;

class LevelBadge extends StatelessWidget {
  const LevelBadge({
    required this.level,
    super.key,
    this.size = 48,
    this.showLabel = true,
  });

  final OperatorLevel level;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final (color, icon, gradient) = _levelAssets(level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 10,
          height: size + 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withAlpha(90),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: size * 0.45),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          Text(
            level.displayName,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  static (Color, IconData, List<Color>) _levelAssets(OperatorLevel level) {
    return switch (level) {
      OperatorLevel.plata => (
          AppColors.silver,
          Icons.star_rounded,
          [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)],
        ),
      OperatorLevel.oro => (
          AppColors.gold,
          Icons.star_rounded,
          [const Color(0xFFFFB300), const Color(0xFFFFD54F)],
        ),
      OperatorLevel.platino => (
          AppColors.platinum,
          Icons.workspace_premium_rounded,
          [const Color(0xFF90CAF9), const Color(0xFFE3F2FD)],
        ),
      OperatorLevel.esmeralda => (
          AppColors.emerald,
          Icons.diamond_rounded,
          [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
        ),
      OperatorLevel.diamante => (
          AppColors.diamond,
          Icons.diamond_rounded,
          [const Color(0xFF1565C0), const Color(0xFF64B5F6)],
        ),
    };
  }
}

class LevelProgressBar extends StatelessWidget {
  const LevelProgressBar({
    required this.currentPoints,
    required this.level,
    this.nextLevelPoints,
    super.key,
  });

  final int currentPoints;
  final OperatorLevel level;
  final int? nextLevelPoints;

  @override
  Widget build(BuildContext context) {
    final nextLevel = level.next;
    if (nextLevel == null) {
      return _buildMaxLevel(context);
    }

    final target = nextLevelPoints ?? _defaultNextPoints(level);
    final progress = (currentPoints / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso a ${nextLevel.displayName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
            ),
            Text(
              '$currentPoints / $target pts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMaxLevel(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.emoji_events, color: AppColors.diamond, size: 16),
        const SizedBox(width: 8),
        Text(
          'Nivel máximo alcanzado',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.diamond,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  // TODO(fase-3): Reemplazar valores hardcodeados con los umbrales reales
  // de la tabla `niveles_operador` en Supabase (columna `puntos_minimos`).
  // El widget debería recibir `nextLevelPoints` como parámetro obligatorio
  // una vez que el profileProvider exponga esos datos.
  int _defaultNextPoints(OperatorLevel level) => switch (level) {
        OperatorLevel.plata => 5000,
        OperatorLevel.oro => 15000,
        OperatorLevel.platino => 30000,
        OperatorLevel.esmeralda => 60000,
        OperatorLevel.diamante => 60000,
      };
}
