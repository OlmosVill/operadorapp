import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';
import 'package:operadorapp/features/ranking/presentation/providers/ranking_provider.dart';
import 'package:operadorapp/features/ranking/presentation/widgets/rank_change_indicator.dart';
import 'package:operadorapp/features/ranking/presentation/widgets/ranking_podium.dart';
import 'package:operadorapp/features/ranking/presentation/widgets/ranking_tile.dart';
import 'package:operadorapp/shared/widgets/app_error_widget.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider);
    final periodo = ref.watch(rankingPeriodoProvider);
    final myId = ref.watch(profileProvider).value?.id;
    final myEntry = ref.watch(myRankingEntryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _PeriodoSelector(
            periodo: periodo,
            onChanged: (value) =>
                ref.read(rankingPeriodoProvider.notifier).state = value,
          ),
        ),
      ),
      body: rankingAsync.when(
        loading: () => const AppLoadingWidget(message: 'Cargando ranking...'),
        error: (error, _) => AppErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(rankingProvider),
        ),
        data: (entries) => entries.isEmpty
            ? const _EmptyRanking()
            : _RankingBody(
                entries: entries,
                myOperadorId: myId,
                onRefresh: () async {
                  await ref
                      .read(rankingRepositoryProvider)
                      .refresh(ref.read(rankingPeriodoProvider));
                },
              ),
      ),
      bottomNavigationBar:
          myEntry == null ? null : _MyPositionBar(entry: myEntry),
    );
  }
}

// ─── Selector de periodo ─────────────────────────────────────────────────────

class _PeriodoSelector extends StatelessWidget {
  const _PeriodoSelector({required this.periodo, required this.onChanged});

  final RankingPeriodo periodo;
  final ValueChanged<RankingPeriodo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SegmentedButton<RankingPeriodo>(
        segments: RankingPeriodo.values
            .map(
              (p) => ButtonSegment<RankingPeriodo>(
                value: p,
                label: Text(p.displayName),
                icon: Icon(
                  p == RankingPeriodo.global
                      ? Icons.emoji_events_outlined
                      : Icons.calendar_month_outlined,
                  size: 18,
                ),
              ),
            )
            .toList(),
        selected: {periodo},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

// ─── Body ────────────────────────────────────────────────────────────────────

class _RankingBody extends StatelessWidget {
  const _RankingBody({
    required this.entries,
    required this.myOperadorId,
    required this.onRefresh,
  });

  final List<RankingEntry> entries;
  final String? myOperadorId;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final podio = entries.take(3).toList();
    final resto = entries.length > 3 ? entries.sublist(3) : <RankingEntry>[];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: RankingPodium(top: podio, myOperadorId: myOperadorId)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0),
          ),
          const SliverToBoxAdapter(child: _TableHeader()),
          SliverList.builder(
            itemCount: resto.length,
            itemBuilder: (_, i) => RankingTile(
              entry: resto[i],
              isMe: resto[i].operadorId == myOperadorId,
            )
                .animate()
                .fadeIn(
                  duration: 300.ms,
                  delay: Duration(milliseconds: 30 * i),
                )
                .slideX(begin: 0.03, end: 0),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 8),
      child: Row(
        children: [
          Text('LUGAR', style: style),
          const SizedBox(width: 24),
          Text('OPERADOR', style: style),
          const Spacer(),
          Text('PUNTOS', style: style),
          const SizedBox(width: 16),
          Text('CAMBIO', style: style),
        ],
      ),
    );
  }
}

// ─── Mi posición (barra fija) ────────────────────────────────────────────────

class _MyPositionBar extends StatelessWidget {
  const _MyPositionBar({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.amber.withAlpha(28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amber.withAlpha(100)),
        ),
        child: Row(
          children: [
            Text(
              'Tu lugar',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '#${entry.posicion}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            LevelChip(level: entry.nivel),
            const SizedBox(width: 8),
            RatingLabel(calificacion: entry.calificacion),
            const SizedBox(width: 10),
            RankChangeIndicator.fromEntry(entry),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: AppColors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Ranking no disponible',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Aún no hay posiciones para este periodo. '
              'Conéctate para sincronizar.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
