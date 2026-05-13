import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:operadorapp/features/trips/data/datasources/trips_local_datasource.dart';
import 'package:operadorapp/features/trips/data/repositories/trips_repository_impl.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_detail.dart';
import 'package:operadorapp/features/trips/domain/repositories/trips_repository.dart';
import 'package:operadorapp/features/trips/domain/usecases/get_trip_detail_usecase.dart';
import 'package:operadorapp/features/trips/domain/usecases/get_trips_usecase.dart';

// ─── Datasources & Repository ────────────────────────────────────────────────

final tripsLocalDatasourceProvider = Provider<TripsLocalDatasource>(
  (ref) => DriftTripsLocalDatasource(ref.read(appDatabaseProvider)),
);

final tripsRepositoryProvider = Provider<TripsRepository>(
  (ref) => TripsRepositoryImpl(
    localDatasource: ref.read(tripsLocalDatasourceProvider),
    syncService: ref.read(syncServiceProvider),
    logger: ref.read(loggerProvider),
  ),
);

final getTripsUseCaseProvider = Provider<GetTripsUseCase>(
  (ref) => GetTripsUseCase(ref.read(tripsRepositoryProvider)),
);

final getTripDetailUseCaseProvider = Provider<GetTripDetailUseCase>(
  (ref) => GetTripDetailUseCase(ref.read(tripsRepositoryProvider)),
);

// ─── Lista de viajes reactiva ───────────────────────────────────────────────

final tripsProvider = StreamProvider<List<Trip>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final operadorId = authAsync.value?.operatorId ?? '';

  if (operadorId.isEmpty) return const Stream.empty();

  return ref
      .read(getTripsUseCaseProvider)
      .call(operadorId: operadorId)
      .map(
        (result) => result.fold(
          (error) => throw _toException(error),
          (trips) => trips,
        ),
      );
});

// ─── Detalle de viaje ───────────────────────────────────────────────────────

// FutureProvider.autoDispose.family devuelve un tipo complejo; la anotación
// explícita haría la declaración ilegible.
// ignore: specify_nonobvious_property_types
final tripDetailProvider =
    FutureProvider.autoDispose.family<TripDetail, String>((ref, tripId) async {
  final result =
      await ref.read(getTripDetailUseCaseProvider).call(tripId: tripId);
  return result.fold(
    (error) => throw _toException(error),
    (detail) => detail,
  );
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

Exception _toException(AppError error) => switch (error) {
      NotFoundError(:final resource) =>
        Exception('No encontrado: ${resource ?? 'recurso'}'),
      NetworkError(:final message) =>
        Exception('Sin conexión: ${message ?? ''}'),
      _ => Exception(error.toString()),
    };
