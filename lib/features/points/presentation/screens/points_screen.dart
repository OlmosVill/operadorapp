import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';
import 'package:operadorapp/features/points/presentation/providers/points_provider.dart';
import 'package:operadorapp/features/points/presentation/widgets/movement_tile.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/profile/presentation/widgets/level_badge.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

// Umbrales de nivel alineados con seed.sql
const _levelThresholds = <OperatorLevel, (int, int?)>{
  OperatorLevel.plata: (0, 4999),
  OperatorLevel.oro: (5000, 14999),
  OperatorLevel.platino: (15000, 29999),
  OperatorLevel.esmeralda: (30000, 59999),
  OperatorLevel.diamante: (60000, null),
};

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final movementsAsync = ref.watch(movementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Puntos')),
      body: profileAsync.when(
        loading: () => const AppLoadingWidget(message: 'Cargando...'),
        error: (_, __) => const SizedBox.shrink(),
        data: (profile) => _PointsBody(
          profile: profile,
          movementsAsync: movementsAsync,
        ),
      ),
    );
  }
}

// ─── Body ───────────────────────────────────────────────────────────────────

class _PointsBody extends StatelessWidget {
  const _PointsBody({required this.profile, required this.movementsAsync});

  final OperatorProfile profile;
  final AsyncValue<List<PointMovement>> movementsAsync;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _BalanceSection(profile: profile)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              _LevelProgressSection(profile: profile)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 80.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Historial de movimientos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 140.ms),
              const SizedBox(height: 8),
            ],
          ),
        ),
        movementsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: AppLoadingWidget(message: ''),
          ),
          error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (movements) {
            if (movements.isEmpty) {
              return const SliverToBoxAdapter(child: _EmptyMovements());
            }
            return SliverList.builder(
              itemCount: movements.length,
              itemBuilder: (_, i) => MovementTile(movement: movements[i])
                  .animate()
                  .fadeIn(duration: 300.ms, delay: (160 + i * 30).ms),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ─── Balance ─────────────────────────────────────────────────────────────────

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({required this.profile});

  final OperatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A2800), Color(0xFF2A1800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withAlpha(40)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.stars_rounded,
                color: AppColors.amber,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '${profile.availablePoints}',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'pts disponibles',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.amber.withAlpha(200),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MiniStat(
                label: 'Ganados',
                value: profile.totalPoints,
                icon: Icons.trending_up_rounded,
                color: Colors.green,
              ),
              Container(
                width: 1,
                height: 36,
                color: AppColors.amber.withAlpha(40),
              ),
              _MiniStat(
                label: 'Canjeados',
                value: profile.totalPoints - profile.availablePoints,
                icon: Icons.card_giftcard_rounded,
                color: AppColors.amber.withAlpha(180),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              '$value pts',
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.amber.withAlpha(150),
          ),
        ),
      ],
    );
  }
}

// ─── Progreso de nivel ───────────────────────────────────────────────────────

class _LevelProgressSection extends StatelessWidget {
  const _LevelProgressSection({required this.profile});

  final OperatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = profile.level;
    final nextLevel = level.next;
    final threshold = _levelThresholds[level];
    final nextThreshold = nextLevel != null
        ? _levelThresholds[nextLevel]
        : null;

    final rangeMin = threshold?.$1 ?? 0;
    final rangeMax = nextThreshold?.$1;

    final progress = rangeMax != null
        ? ((profile.availablePoints - rangeMin) /
                (rangeMax - rangeMin))
            .clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.asphaltCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.asphaltBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LevelBadge(level: level, size: 36),
              const Spacer(),
              if (nextLevel != null) ...[
                Text(
                  'Siguiente: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
                LevelBadge(level: nextLevel, size: 28),
              ] else
                Text(
                  'Nivel máximo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  theme.colorScheme.onSurface.withAlpha(20),
              color: AppColors.amber,
            ),
          ),
          if (rangeMax != null) ...[
            const SizedBox(height: 6),
            Text(
              '${profile.availablePoints} / $rangeMax pts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyMovements extends StatelessWidget {
  const _EmptyMovements();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.stars_outlined,
            size: 56,
            color: AppColors.amber,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin movimientos aún',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Completa viajes para ganar puntos.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(120),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
