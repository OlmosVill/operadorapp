import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';
import 'package:operadorapp/features/points/domain/repositories/points_repository.dart';

class WatchMovementsUsecase {
  const WatchMovementsUsecase(this._repository);

  final PointsRepository _repository;

  Stream<Either<AppError, List<PointMovement>>> call(
    String operadorId,
  ) =>
      _repository.watchMovimientos(operadorId);
}
