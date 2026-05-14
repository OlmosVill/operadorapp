import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/trucks/domain/entities/truck.dart';

abstract interface class TrucksRepository {
  Stream<Either<AppError, List<TruckSummary>>> watchByOperador(
    String operadorId,
  );

  Future<Either<AppError, List<TruckReport>>> getReportes(
    String tractoId,
  );

  Future<Either<AppError, double?>> getRendimientoPromedio(
    String tractoId,
    String operadorId,
  );
}
