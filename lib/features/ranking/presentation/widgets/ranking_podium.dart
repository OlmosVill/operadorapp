import 'package:flutter/material.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';
import 'package:operadorapp/features/ranking/presentation/widgets/rank_change_indicator.dart';
import 'package:operadorapp/features/ranking/presentation/widgets/ranking_tile.dart';

/// Podio de los 3 primeros lugares: 2º — 1º — 3º.
class RankingPodium extends StatelessWidget {
  const RankingPodium({
    required this.top,
    required this.myOperadorId,
    super.key,
  });

  /// Primeros lugares del ranking, ya ordenados (máximo 3 se pintan).
  final List<RankingEntry> top;
  final String? myOperadorId;

  @override
  Widget build(BuildContext context) {
    if (top.isEmpty) return const SizedBox.shrink();

    final primero = top.first;
    final segundo = top.length > 1 ? top[1] : null;
    final tercero = top.length > 2 ? top[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: segundo == null
                ? const SizedBox.shrink()
                : _PodiumSpot(
                    entry: segundo,
                    height: 90,
                    isMe: segundo.operadorId == myOperadorId,
                  ),
          ),
          Expanded(
            child: _PodiumSpot(
              entry: primero,
              height: 120,
              isMe: primero.operadorId == myOperadorId,
            ),
          ),
          Expanded(
            child: tercero == null
                ? const SizedBox.shrink()
                : _PodiumSpot(
                    entry: tercero,
                    height: 70,
                    isMe: tercero.operadorId == myOperadorId,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.entry,
    required this.height,
    required this.isMe,
  });

  final RankingEntry entry;
  final double height;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (entry.posicion) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      _ => const Color(0xFFCD7F32),
    };
    final esPrimero = entry.posicion == 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (esPrimero)
          Icon(Icons.workspace_premium_rounded, color: color, size: 28),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: RankingAvatar(entry: entry, size: esPrimero ? 56 : 46),
        ),
        const SizedBox(height: 6),
        Text(
          _primerNombre(entry.nombreCompleto),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isMe ? AppColors.amber : null,
          ),
        ),
        const SizedBox(height: 2),
        RankChangeIndicator.fromEntry(entry, compact: true),
        const SizedBox(height: 6),
        Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withAlpha(70), color.withAlpha(18)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: color.withAlpha(110)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${entry.posicion}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.puntos} pts',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              RatingLabel(calificacion: entry.calificacion),
            ],
          ),
        ),
      ],
    );
  }

  String _primerNombre(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    return partes.isEmpty ? nombre : partes.first;
  }
}
