import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';

abstract interface class PointsRepository {
  Stream<Either<AppError, List<PointMovement>>> watchMovimientos(
    String operadorId,
  );
}
