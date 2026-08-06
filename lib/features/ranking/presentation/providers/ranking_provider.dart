import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/ranking/data/repositories/ranking_repository_impl.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';
import 'package:operadorapp/features/ranking/domain/repositories/ranking_repository.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return RankingRepositoryImpl(
    ref.watch(appDatabaseProvider).rankingDao,
    ref.watch(syncServiceProvider),
  );
});

final rankingPeriodoProvider = StateProvider<RankingPeriodo>(
  (_) => RankingPeriodo.global,
);

final rankingProvider = StreamProvider<List<RankingEntry>>((ref) {
  final periodo = ref.watch(rankingPeriodoProvider);
  return ref
      .watch(rankingRepositoryProvider)
      .watchRanking(periodo)
      .map((e) => e.getOrElse((_) => []));
});

/// Fila del operador autenticado dentro del ranking visible.
final myRankingEntryProvider = Provider<RankingEntry?>((ref) {
  final operadorId = ref.watch(profileProvider).value?.id;
  final entries = ref.watch(rankingProvider).value;
  if (operadorId == null || entries == null) return null;
  for (final entry in entries) {
    if (entry.operadorId == operadorId) return entry;
  }
  return null;
});

final rankingTotalProvider = Provider<int>(
  (ref) => ref.watch(rankingProvider).value?.length ?? 0,
);
