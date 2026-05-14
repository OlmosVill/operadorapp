import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/canje_sheet.dart';

class RoadmapMilestone extends StatelessWidget {
  const RoadmapMilestone({
    required this.premio,
    required this.availablePoints,
    required this.operatorLevel,
    required this.isLast,
    required this.isTarget,
    super.key,
  });

  final Premio premio;
  final int availablePoints;
  final OperatorLevel operatorLevel;
  final bool isLast;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    final reached = availablePoints >= premio.costoPuntos;
    final progress =
        (availablePoints / premio.costoPuntos).clamp(0.0, 1.0);
    final (color, icon) = _tipoAssets(premio.tipo);
    final canCanje = reached &&
        (premio.nivelMinimo == null ||
            operatorLevel.index >= premio.nivelMinimo!.index);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrackColumn(
          reached: reached,
          isTarget: isTarget,
          isLast: isLast,
          color: color,
          icon: icon,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MilestoneCard(
            premio: premio,
            reached: reached,
            canCanje: canCanje,
            progress: progress,
            availablePoints: availablePoints,
            color: color,
            onCanje: canCanje ? () => _openSheet(context) : null,
          ),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => CanjeSheet(premio: premio),
      ),
    );
  }

  static (Color, IconData) _tipoAssets(PremioTipo tipo) =>
      switch (tipo) {
        PremioTipo.tarjetaRegalo => (
            Colors.green,
            Icons.card_giftcard_rounded,
          ),
        PremioTipo.producto => (
            Colors.blue,
            Icons.inventory_2_rounded,
          ),
        PremioTipo.experiencia => (
            Colors.purple,
            Icons.event_rounded,
          ),
        PremioTipo.vehiculo => (
            AppColors.amber,
            Icons.local_shipping_rounded,
          ),
        PremioTipo.otro => (
            AppColors.textSecondaryDark,
            Icons.redeem_rounded,
          ),
      };
}

// ─── Track column ────────────────────────────────────────────────────────────

class _TrackColumn extends StatelessWidget {
  const _TrackColumn({
    required this.reached,
    required this.isTarget,
    required this.isLast,
    required this.color,
    required this.icon,
  });

  final bool reached;
  final bool isTarget;
  final bool isLast;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final trackColor =
        reached ? color : Colors.grey.shade300;

    return SizedBox(
      width: 40,
      child: Column(
        children: [
          _NodeCircle(
            reached: reached,
            isTarget: isTarget,
            color: color,
            icon: icon,
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 72,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}

class _NodeCircle extends StatelessWidget {
  const _NodeCircle({
    required this.reached,
    required this.isTarget,
    required this.color,
    required this.icon,
  });

  final bool reached;
  final bool isTarget;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? color : Colors.transparent,
        border: reached
            ? null
            : Border.all(color: color, width: 2),
        boxShadow: reached
            ? [
                BoxShadow(
                  color: color.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 20,
        color: reached ? Colors.white : color,
      ),
    );

    if (isTarget) {
      return circle
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.88, 0.88),
            end: const Offset(1.12, 1.12),
            duration: 900.ms,
            curve: Curves.easeInOut,
          );
    }

    return circle;
  }
}

// ─── Milestone card ──────────────────────────────────────────────────────────

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({
    required this.premio,
    required this.reached,
    required this.canCanje,
    required this.progress,
    required this.availablePoints,
    required this.color,
    required this.onCanje,
  });

  final Premio premio;
  final bool reached;
  final bool canCanje;
  final double progress;
  final int availablePoints;
  final Color color;
  final VoidCallback? onCanje;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = premio.costoPuntos - availablePoints;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    premio.nombre,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (premio.nivelMinimo != null) ...[
                  const SizedBox(width: 8),
                  _LevelChip(level: premio.nivelMinimo!),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              premio.tipo.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reached
                      ? '¡Alcanzado!'
                      : 'Faltan ${remaining > 0 ? remaining : 0} pts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: reached
                        ? Colors.green
                        : AppColors.textSecondaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      size: 13,
                      color: color,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${premio.costoPuntos} pts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (canCanje) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onCanje,
                  child: const Text('Canjear'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final OperatorLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        level.displayName,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
