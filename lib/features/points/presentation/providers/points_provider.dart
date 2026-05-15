import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/points/data/datasources/points_local_datasource.dart';
import 'package:operadorapp/features/points/data/repositories/points_repository_impl.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';
import 'package:operadorapp/features/points/domain/usecases/watch_movements_usecase.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';

// ─── Datasource / Repository / Usecase ─────────────────────────────────────

final _pointsLocalProvider = Provider<PointsLocalDatasource>(
  (ref) => PointsLocalDatasource(ref.watch(appDatabaseProvider)),
);

final _pointsRepoProvider = Provider<PointsRepositoryImpl>(
  (ref) => PointsRepositoryImpl(
    ref.watch(_pointsLocalProvider),
    ref.watch(syncServiceProvider),
  ),
);

final _watchMovementsProvider = Provider<WatchMovementsUsecase>(
  (ref) => WatchMovementsUsecase(ref.watch(_pointsRepoProvider)),
);

// ─── Historial de movimientos ───────────────────────────────────────────────

final movementsProvider = StreamProvider<List<PointMovement>>((ref) {
  final operadorId = ref.watch(profileProvider).value?.id;
  if (operadorId == null || operadorId.isEmpty) {
    return const Stream.empty();
  }

  return ref.watch(_watchMovementsProvider).call(operadorId).map(
        (e) => e.fold(
          (err) => throw Exception(err.toString()),
          (v) => v,
        ),
      );
});
