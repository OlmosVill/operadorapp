import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/rewards/data/datasources/rewards_local_datasource.dart';
import 'package:operadorapp/features/rewards/data/datasources/rewards_remote_datasource.dart';
import 'package:operadorapp/features/rewards/data/repositories/rewards_repository_impl.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/domain/usecases/canjear_usecase.dart';
import 'package:operadorapp/features/rewards/domain/usecases/get_premios_usecase.dart';

// ─── Datasources / Repository / Usecases ───────────────────────────────────

final _rewardsLocalProvider = Provider<RewardsLocalDatasource>(
  (ref) => RewardsLocalDatasource(ref.watch(appDatabaseProvider)),
);

final _rewardsRemoteProvider = Provider<RewardsRemoteDatasource>(
  (ref) => RewardsRemoteDatasource(ref.watch(supabaseClientProvider)),
);

final _rewardsRepoProvider = Provider<RewardsRepositoryImpl>(
  (ref) => RewardsRepositoryImpl(
    ref.watch(_rewardsLocalProvider),
    ref.watch(_rewardsRemoteProvider),
  ),
);

final _getPremiosProvider = Provider<GetPremiosUsecase>(
  (ref) => GetPremiosUsecase(ref.watch(_rewardsRepoProvider)),
);

final canjearUsecaseProvider = Provider<CanjearUsecase>(
  (ref) => CanjearUsecase(ref.watch(_rewardsRepoProvider)),
);

// ─── Catálogo ───────────────────────────────────────────────────────────────

final premiosProvider = StreamProvider<List<Premio>>((ref) {
  return ref.watch(_getPremiosProvider).call().map(
        (e) => e.fold(
          (err) => throw Exception(err.toString()),
          (v) => v,
        ),
      );
});

// ─── Historial de canjes ─────────────────────────────────────────────────

final canjesProvider = StreamProvider<List<Canje>>((ref) {
  final operadorId = ref.watch(profileProvider).value?.id;
  if (operadorId == null || operadorId.isEmpty) {
    return const Stream.empty();
  }

  return ref.watch(_rewardsRepoProvider).watchCanjes(operadorId).map(
        (e) => e.fold(
          (err) => throw Exception(err.toString()),
          (v) => v,
        ),
      );
});
