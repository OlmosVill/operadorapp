import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_detail.dart';

abstract interface class TripsRepository {
  Stream<Either<AppError, List<Trip>>> watchTrips({required String operadorId});

  Future<Either<AppError, List<Trip>>> getTrips({
    required String operadorId,
    int limit,
    int offset,
  });

  Future<Either<AppError, TripDetail>> getTripDetail({required String tripId});
}
