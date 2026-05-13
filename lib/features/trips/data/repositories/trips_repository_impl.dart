import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/core/services/sync_service.dart';
import 'package:operadorapp/features/trips/data/datasources/trips_local_datasource.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_detail.dart';
import 'package:operadorapp/features/trips/domain/repositories/trips_repository.dart';

final class TripsRepositoryImpl implements TripsRepository {
  const TripsRepositoryImpl({
    required TripsLocalDatasource localDatasource,
    required SyncService syncService,
    required Logger logger,
  })  : _local = localDatasource,
        _sync = syncService,
        _logger = logger;

  final TripsLocalDatasource _local;
  final SyncService _sync;
  final Logger _logger;

  @override
  Stream<Either<AppError, List<Trip>>> watchTrips({
    required String operadorId,
  }) async* {
    unawaited(_sync.syncTrips(operadorId));
    await for (final trips in _local.watchTrips(operadorId)) {
      yield Right(trips);
    }
  }

  @override
  Future<Either<AppError, List<Trip>>> getTrips({
    required String operadorId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final trips =
          await _local.getTrips(operadorId, limit: limit, offset: offset);
      return Right(trips);
    } catch (e, st) {
      _logger.e('getTrips error', error: e, stackTrace: st);
      return Left(UnexpectedError(error: e, stackTrace: st));
    }
  }

  @override
  Future<Either<AppError, TripDetail>> getTripDetail({
    required String tripId,
  }) async {
    try {
      final trip = await _local.getTripById(tripId);
      if (trip == null) {
        return const Left(NotFoundError(resource: 'viaje'));
      }

      // Sync detail before reading — acceptable latency for first load
      await _sync.syncTripDetail(tripId);

      final incidents = await _local.getIncidents(tripId);
      final alerts = await _local.getAlerts(tripId);
      final gpsPoints = await _local.getGpsPoints(tripId);

      return Right(
        TripDetail(
          trip: trip,
          incidents: incidents,
          securityAlerts: alerts,
          gpsPoints: gpsPoints,
        ),
      );
    } catch (e, st) {
      _logger.e('getTripDetail error', error: e, stackTrace: st);
      return Left(UnexpectedError(error: e, stackTrace: st));
    }
  }
}
