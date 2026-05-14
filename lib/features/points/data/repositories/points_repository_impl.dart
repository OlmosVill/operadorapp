import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/points/data/datasources/points_local_datasource.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';
import 'package:operadorapp/features/points/domain/repositories/points_repository.dart';

class PointsRepositoryImpl implements PointsRepository {
  const PointsRepositoryImpl(this._local);

  final PointsLocalDatasource _local;

  @override
  Stream<Either<AppError, List<PointMovement>>> watchMovimientos(
    String operadorId,
  ) async* {
    try {
      await for (final movements
          in _local.watchMovimientos(operadorId)) {
        yield Right(movements);
      }
    } on Object catch (e) {
      yield Left(UnexpectedError(error: e));
    }
  }
}
