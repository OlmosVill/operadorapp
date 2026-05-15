import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/core/services/sync_service.dart';
import 'package:operadorapp/features/points/data/datasources/points_local_datasource.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';
import 'package:operadorapp/features/points/domain/repositories/points_repository.dart';

class PointsRepositoryImpl implements PointsRepository {
  const PointsRepositoryImpl(this._local, this._sync);

  final PointsLocalDatasource _local;
  final SyncService _sync;

  @override
  Stream<Either<AppError, List<PointMovement>>> watchMovimientos(
    String operadorId,
  ) async* {
    unawaited(_sync.syncMovimientos(operadorId));
    try {
      await for (final movements in _local.watchMovimientos(operadorId)) {
        yield Right(movements);
      }
    } on Object catch (e) {
      yield Left(UnexpectedError(error: e));
    }
  }
}
