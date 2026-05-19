import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/canje_sheet.dart';

// ─── Trophy Milestone ────────────────────────────────────────────────────────

class TrophyMilestone extends StatelessWidget {
  const TrophyMilestone({
    required this.premio,
    required this.availablePoints,
    required this.operatorLevel,
    required this.isLeft,
    required this.isUnlocked,
    required this.isTarget,
    super.key,
  });

  final Premio premio;
  final int availablePoints;
  final OperatorLevel operatorLevel;
  final bool isLeft;
  final bool isUnlocked;
  final bool isTarget;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _tipoAssets(premio.tipo);
    final canCanje = isUnlocked &&
        (premio.nivelMinimo == null ||
            operatorLevel.index >= premio.nivelMinimo!.index);

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: isLeft
                ? _PrizeCard(
                    premio: premio,
                    isLeft: true,
                    isUnlocked: isUnlocked,
                    isTarget: isTarget,
                    canCanje: canCanje,
                    color: color,
                    icon: icon,
                    availablePoints: availablePoints,
                  )
                : const SizedBox(),
          ),
          _PathColumn(
            isUnlocked: isUnlocked,
            isTarget: isTarget,
            color: color,
            icon: icon,
          ),
          Expanded(
            flex: 4,
            child: !isLeft
                ? _PrizeCard(
                    premio: premio,
                    isLeft: false,
                    isUnlocked: isUnlocked,
                    isTarget: isTarget,
                    canCanje: canCanje,
                    color: color,
                    icon: icon,
                    availablePoints: availablePoints,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  static (Color, IconData) _tipoAssets(PremioTipo tipo) => switch (tipo) {
        PremioTipo.tarjetaRegalo => (
          Colors.green,
          Icons.card_giftcard_rounded,
        ),
        PremioTipo.producto => (Colors.blue, Icons.inventory_2_rounded),
        PremioTipo.experiencia => (Colors.purple, Icons.event_rounded),
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

// ─── Center path column ──────────────────────────────────────────────────────

class _PathColumn extends StatelessWidget {
  const _PathColumn({
    required this.isUnlocked,
    required this.isTarget,
    required this.color,
    required this.icon,
  });

  final bool isUnlocked;
  final bool isTarget;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final lineColor =
        isUnlocked ? AppColors.amber.withAlpha(160) : Colors.grey.shade300;

    return SizedBox(
      width: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Center(
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
          _PathNode(
            isUnlocked: isUnlocked,
            isTarget: isTarget,
            color: color,
            icon: icon,
          ),
        ],
      ),
    );
  }
}

// ─── Node circle on the path ─────────────────────────────────────────────────

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.isUnlocked,
    required this.isTarget,
    required this.color,
    required this.icon,
  });

  final bool isUnlocked;
  final bool isTarget;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final node = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked ? color : Colors.grey.shade100,
        border: isTarget
            ? Border.all(color: color, width: 2.5)
            : isUnlocked
                ? null
                : Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: color.withAlpha(80),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 18,
        color: isUnlocked ? Colors.white : Colors.grey.shade400,
      ),
    );

    if (isTarget) {
      return node
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.85, 0.85),
            end: const Offset(1.18, 1.18),
            duration: 900.ms,
            curve: Curves.easeInOut,
          );
    }

    return node;
  }
}

// ─── Prize card (left or right of path) ─────────────────────────────────────

class _PrizeCard extends StatelessWidget {
  const _PrizeCard({
    required this.premio,
    required this.isLeft,
    required this.isUnlocked,
    required this.isTarget,
    required this.canCanje,
    required this.color,
    required this.icon,
    required this.availablePoints,
  });

  final Premio premio;
  final bool isLeft;
  final bool isUnlocked;
  final bool isTarget;
  final bool canCanje;
  final Color color;
  final IconData icon;
  final int availablePoints;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = (premio.costoPuntos - availablePoints).clamp(0, 999999);

    final connector = Container(
      width: 20,
      height: 2,
      color: isUnlocked
          ? AppColors.amber.withAlpha(140)
          : Colors.grey.shade300,
    );

    final card = GestureDetector(
      onTap: canCanje ? () => _openSheet(context) : null,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          isLeft ? 8 : 0,
          16,
          isLeft ? 0 : 8,
          16,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUnlocked ? color.withAlpha(18) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTarget
                ? color
                : isUnlocked
                    ? color.withAlpha(65)
                    : Colors.grey.shade200,
            width: isTarget ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: color.withAlpha(35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? color : Colors.grey.shade300,
                boxShadow: isUnlocked
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
                isUnlocked ? icon : Icons.lock_rounded,
                size: 20,
                color: isUnlocked ? Colors.white : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 11,
                  color: isUnlocked ? color : Colors.grey.shade500,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${premio.costoPuntos}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? color : Colors.grey.shade500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              premio.nombre,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isUnlocked
                    ? theme.colorScheme.onSurface
                    : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (canCanje) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Canjear',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (!isUnlocked) ...[
              const SizedBox(height: 3),
              Text(
                '-$remaining pts',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );

    return Row(
      mainAxisAlignment:
          isLeft ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isLeft
          ? [Expanded(child: card), connector]
          : [connector, Expanded(child: card)],
    );
  }
}

// ─── Level section banner ────────────────────────────────────────────────────

class TrophyLevelBanner extends StatelessWidget {
  const TrophyLevelBanner({required this.level, super.key});

  final OperatorLevel level;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _levelAssets(level);

    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Container(width: 3, height: 72, color: Colors.grey.shade200),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: color.withAlpha(100),
                    thickness: 1.5,
                    endIndent: 8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(22),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color.withAlpha(110), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        level.displayName.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: color.withAlpha(100),
                    thickness: 1.5,
                    indent: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (Color, IconData) _levelAssets(OperatorLevel level) => switch (level) {
        OperatorLevel.plata => (
          Colors.blueGrey.shade400,
          Icons.shield_rounded,
        ),
        OperatorLevel.oro => (
          AppColors.amber,
          Icons.workspace_premium_rounded,
        ),
        OperatorLevel.platino => (
          Colors.cyan.shade400,
          Icons.diamond_rounded,
        ),
        OperatorLevel.esmeralda => (
          Colors.green.shade500,
          Icons.eco_rounded,
        ),
        OperatorLevel.diamante => (
          Colors.blue.shade400,
          Icons.auto_awesome_rounded,
        ),
      };
}

// ─── Current position marker ─────────────────────────────────────────────────

class TrophyPositionMarker extends StatelessWidget {
  const TrophyPositionMarker({required this.availablePoints, super.key});

  final int availablePoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Container(
              width: 3,
              height: 88,
              color: AppColors.amber.withAlpha(60),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.amber.withAlpha(80),
                  thickness: 1,
                  endIndent: 8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber.withAlpha(18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.amber, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.amber.withAlpha(40),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.amber,
                      size: 22,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shimmer(
                          duration: 1500.ms,
                          color: Colors.white.withAlpha(100),
                        ),
                    const SizedBox(height: 2),
                    const Text(
                      'ESTÁS AQUÍ',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '$availablePoints pts',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryDark,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.amber.withAlpha(80),
                  thickness: 1,
                  indent: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
