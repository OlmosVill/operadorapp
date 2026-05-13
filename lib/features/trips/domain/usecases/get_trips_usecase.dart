import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/repositories/trips_repository.dart';

class GetTripsUseCase {
  const GetTripsUseCase(this._repository);

  final TripsRepository _repository;

  Stream<Either<AppError, List<Trip>>> call({required String operadorId}) =>
      _repository.watchTrips(operadorId: operadorId);
}
