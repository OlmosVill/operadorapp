import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/roadmap_milestone.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

// Exposed as top-level for testability
List<Premio> filterAndSortPremios(
  List<Premio> premios,
  OperatorLevel? levelFilter,
) {
  return (levelFilter == null
      ? List<Premio>.of(premios)
      : premios
          .where(
            (p) => p.nivelMinimo == null || p.nivelMinimo == levelFilter,
          )
          .toList())
    ..sort((a, b) => a.costoPuntos.compareTo(b.costoPuntos));
}

class RewardsRoadmapScreen extends ConsumerStatefulWidget {
  const RewardsRoadmapScreen({super.key});

  @override
  ConsumerState<RewardsRoadmapScreen> createState() =>
      _RewardsRoadmapScreenState();
}

class _RewardsRoadmapScreenState extends ConsumerState<RewardsRoadmapScreen> {
  OperatorLevel? _levelFilter;

  @override
  Widget build(BuildContext context) {
    final premiosAsync = ref.watch(premiosProvider);
    final profile = ref.watch(profileProvider).value;
    final available = profile?.availablePoints ?? 0;
    final operatorLevel = profile?.level ?? OperatorLevel.plata;

    return Scaffold(
      appBar: AppBar(title: const Text('Roadmap de Premios')),
      body: premiosAsync.when(
        loading: () => const AppLoadingWidget(message: 'Cargando...'),
        error: (_, __) => const Center(
          child: Text('Error al cargar premios'),
        ),
        data: (premios) {
          final milestones = filterAndSortPremios(premios, _levelFilter);
          final targetIndex =
              milestones.indexWhere((p) => available < p.costoPuntos);

          return Column(
            children: [
              _LevelFilterBar(
                selected: _levelFilter,
                onChanged: (l) => setState(() => _levelFilter = l),
              ),
              Expanded(
                child: milestones.isEmpty
                    ? const _EmptyRoadmap()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          16,
                          20,
                          40,
                        ),
                        itemCount: milestones.length,
                        itemBuilder: (_, i) => RoadmapMilestone(
                          premio: milestones[i],
                          availablePoints: available,
                          operatorLevel: operatorLevel,
                          isLast: i == milestones.length - 1,
                          isTarget: i == targetIndex,
                        )
                            .animate()
                            .fadeIn(
                              duration: 300.ms,
                              delay: Duration(milliseconds: 60 * i),
                            )
                            .slideX(begin: -0.04, end: 0),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Level filter bar ────────────────────────────────────────────────────────

class _LevelFilterBar extends StatelessWidget {
  const _LevelFilterBar({
    required this.selected,
    required this.onChanged,
  });

  final OperatorLevel? selected;
  final ValueChanged<OperatorLevel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          ...OperatorLevel.values.map(
            (level) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(level.displayName),
                selected: selected == level,
                onSelected: (_) => onChanged(selected == level ? null : level),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyRoadmap extends StatelessWidget {
  const _EmptyRoadmap();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay premios en este nivel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
