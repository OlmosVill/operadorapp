import 'package:flutter/material.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/widgets/level_badge.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';
import 'package:operadorapp/features/ranking/presentation/widgets/rank_change_indicator.dart';

/// Renglón de la tabla de posiciones: lugar, operador, nivel, calificación y
/// el movimiento de lugares respecto al último corte.
class RankingTile extends StatelessWidget {
  const RankingTile({
    required this.entry,
    super.key,
    this.isMe = false,
    this.onTap,
  });

  final RankingEntry entry;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: isMe ? AppColors.amber.withAlpha(24) : null,
        border: isMe
            ? Border.all(color: AppColors.amber.withAlpha(90))
            : Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _PositionLabel(posicion: entry.posicion, isMe: isMe),
                const SizedBox(width: 10),
                RankingAvatar(entry: entry),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe
                            ? '${entry.nombreCompleto} (tú)'
                            : entry.nombreCompleto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isMe ? AppColors.amber : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          LevelChip(level: entry.nivel),
                          const SizedBox(width: 8),
                          RatingLabel(calificacion: entry.calificacion),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.puntos}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'pts',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                RankChangeIndicator.fromEntry(entry, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Lugar ───────────────────────────────────────────────────────────────────

class _PositionLabel extends StatelessWidget {
  const _PositionLabel({required this.posicion, required this.isMe});

  final int posicion;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medalColor = switch (posicion) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => const Color(0xFFCD7F32),
      _ => null,
    };

    return SizedBox(
      width: 34,
      child: Center(
        child: medalColor != null
            ? Icon(Icons.emoji_events_rounded, color: medalColor, size: 24)
            : Text(
                '$posicion',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isMe
                      ? AppColors.amber
                      : theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
      ),
    );
  }
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

class RankingAvatar extends StatelessWidget {
  const RankingAvatar({required this.entry, super.key, this.size = 40});

  final RankingEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = entry.fotoPerfilUrl;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: url != null && url.isNotEmpty
          ? null
          : Text(
              entry.iniciales,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.32,
              ),
            ),
    );
  }
}

// ─── Nivel ───────────────────────────────────────────────────────────────────

class LevelChip extends StatelessWidget {
  const LevelChip({required this.level, super.key});

  final OperatorLevel level;

  @override
  Widget build(BuildContext context) {
    final color = levelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(36),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        level.displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// ─── Calificación ────────────────────────────────────────────────────────────

class RatingLabel extends StatelessWidget {
  const RatingLabel({required this.calificacion, super.key});

  final double? calificacion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = calificacion;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: 14,
          color: value == null
              ? theme.colorScheme.onSurfaceVariant
              : AppColors.amber,
        ),
        const SizedBox(width: 2),
        Text(
          value == null ? 's/c' : value.toStringAsFixed(1),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
