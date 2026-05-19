import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/roadmap_milestone.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

// ─── Road item types ─────────────────────────────────────────────────────────

sealed class _RoadItem {
  const _RoadItem();
}

class _LevelBannerItem extends _RoadItem {
  const _LevelBannerItem(this.level);
  final OperatorLevel level;
}

class _MilestoneItem extends _RoadItem {
  const _MilestoneItem({
    required this.premio,
    required this.isLeft,
    required this.isUnlocked,
    required this.isTarget,
  });
  final Premio premio;
  final bool isLeft;
  final bool isUnlocked;
  final bool isTarget;
}

class _PositionMarkerItem extends _RoadItem {
  const _PositionMarkerItem(this.availablePoints);
  final int availablePoints;
}

// Estimated item heights used for auto-scroll offset calculation.
double _itemHeight(_RoadItem item) => switch (item) {
      _LevelBannerItem _ => 72.0,
      _PositionMarkerItem _ => 88.0,
      _MilestoneItem _ => 180.0,
    };

// ─── Screen ──────────────────────────────────────────────────────────────────

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  final _scrollController = ScrollController();
  bool _scrolled = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_RoadItem> _buildItems(List<Premio> sorted, int available) {
    final items = <_RoadItem>[];
    OperatorLevel? lastLevel;
    var milestoneCount = 0;
    var markerAdded = false;

    for (var i = 0; i < sorted.length; i++) {
      final premio = sorted[i];
      final isUnlocked = available >= premio.costoPuntos;
      final isTarget = !markerAdded && !isUnlocked;

      final level = premio.nivelMinimo ?? OperatorLevel.plata;

      if (level != lastLevel) {
        items.add(_LevelBannerItem(level));
        lastLevel = level;
      }

      if (!isUnlocked && !markerAdded) {
        items.add(_PositionMarkerItem(available));
        markerAdded = true;
      }

      items.add(
        _MilestoneItem(
          premio: premio,
          isLeft: milestoneCount.isEven,
          isUnlocked: isUnlocked,
          isTarget: isTarget,
        ),
      );
      milestoneCount++;
    }

    if (!markerAdded) items.add(_PositionMarkerItem(available));

    return items;
  }

  void _scrollToMarker(List<_RoadItem> items, int markerIndex) {
    if (_scrolled || markerIndex == -1) return;
    _scrolled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      // With reverse:true, item[0] is at the bottom. Accumulating heights
      // from index 0 to markerIndex gives the distance from the bottom
      // content edge to the marker, used to center it in the viewport.
      var distFromBottom = 0.0;
      for (var i = 0; i < markerIndex; i++) {
        distFromBottom += _itemHeight(items[i]);
      }
      final viewport = _scrollController.position.viewportDimension;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final target = (distFromBottom - viewport * 0.6).clamp(0.0, maxExtent);
      unawaited(
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final premiosAsync = ref.watch(premiosProvider);
    final profile = ref.watch(profileProvider).value;
    final available = profile?.availablePoints ?? 0;
    final operatorLevel = profile?.level ?? OperatorLevel.plata;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Catálogo',
            onPressed: () => context.push('/rewards/catalog'),
          ),
        ],
      ),
      body: Column(
        children: [
          _PointsHeader(available: available, level: operatorLevel),
          Expanded(
            child: premiosAsync.when(
              loading: () =>
                  const AppLoadingWidget(message: 'Cargando premios...'),
              error: (_, __) =>
                  const Center(child: Text('Error al cargar premios')),
              data: (premios) {
                final sorted = List<Premio>.of(premios)
                  ..sort((a, b) => a.costoPuntos.compareTo(b.costoPuntos));

                if (sorted.isEmpty) return const _EmptyRoad();

                final items = _buildItems(sorted, available);
                final markerIndex = items.indexWhere(
                  (item) => item is _PositionMarkerItem,
                );
                _scrollToMarker(items, markerIndex);

                return ListView.builder(
                  controller: _scrollController,
                  // reverse: true → item[0] at bottom, scrolling UP reveals
                  // higher-indexed items (higher pts = future prizes).
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return switch (item) {
                      _LevelBannerItem(:final level) =>
                        TrophyLevelBanner(level: level),
                      _PositionMarkerItem(:final availablePoints) =>
                        TrophyPositionMarker(
                          availablePoints: availablePoints,
                        ),
                      _MilestoneItem(
                        :final premio,
                        :final isLeft,
                        :final isUnlocked,
                        :final isTarget,
                      ) =>
                        TrophyMilestone(
                          premio: premio,
                          availablePoints: available,
                          operatorLevel: operatorLevel,
                          isLeft: isLeft,
                          isUnlocked: isUnlocked,
                          isTarget: isTarget,
                        ),
                    };
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Points header ───────────────────────────────────────────────────────────

class _PointsHeader extends StatelessWidget {
  const _PointsHeader({required this.available, required this.level});

  final int available;
  final OperatorLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.amber.withAlpha(14),
        border: Border(
          bottom: BorderSide(color: AppColors.amber.withAlpha(40)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.amber, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$available pts disponibles',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber,
                  ),
                ),
                Text(
                  level.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: AppColors.textSecondaryDark,
            size: 18,
          ),
          Text(
            'Sube para ver más',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryDark,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyRoad extends StatelessWidget {
  const _EmptyRoad();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No hay premios disponibles',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
