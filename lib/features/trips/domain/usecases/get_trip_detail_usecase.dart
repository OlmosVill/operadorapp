import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_detail.dart';
import 'package:operadorapp/features/trips/domain/repositories/trips_repository.dart';

class GetTripDetailUseCase {
  const GetTripDetailUseCase(this._repository);

  final TripsRepository _repository;

  Future<Either<AppError, TripDetail>> call({required String tripId}) =>
      _repository.getTripDetail(tripId: tripId);
}
