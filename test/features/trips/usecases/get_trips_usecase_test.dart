import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/repositories/trips_repository.dart';
import 'package:operadorapp/features/trips/domain/usecases/get_trips_usecase.dart';

class MockTripsRepository extends Mock implements TripsRepository {}

void main() {
  late GetTripsUseCase sut;
  late MockTripsRepository mockRepo;

  const tOperadorId = 'operador-uuid-001';

  final tTrips = [
    Trip(
      id: 'trip-001',
      operadorId: tOperadorId,
      origen: 'Monterrey',
      destino: 'CDMX',
      estado: TripStatus.completado,
      createdAt: DateTime(2025, 5, 1),
      updatedAt: DateTime(2025, 5, 1),
    ),
  ];

  setUp(() {
    mockRepo = MockTripsRepository();
    sut = GetTripsUseCase(mockRepo);
  });

  group('GetTripsUseCase —', () {
    test('retorna stream de Right(trips) desde el repositorio', () {
      when(
        () => mockRepo.watchTrips(operadorId: tOperadorId),
      ).thenAnswer((_) => Stream.value(Right(tTrips)));

      final stream = sut(operadorId: tOperadorId);

      expect(
        stream,
        emits(Right<AppError, List<Trip>>(tTrips)),
      );
    });

    test('propaga Left(error) del repositorio', () {
      const tError = NetworkError(message: 'Sin red');
      when(
        () => mockRepo.watchTrips(operadorId: tOperadorId),
      ).thenAnswer((_) => Stream.value(const Left(tError)));

      final stream = sut(operadorId: tOperadorId);

      expect(
        stream,
        emits(const Left<AppError, List<Trip>>(tError)),
      );
    });

    test('delega directamente al repositorio sin transformar', () {
      when(
        () => mockRepo.watchTrips(operadorId: tOperadorId),
      ).thenAnswer((_) => Stream.value(Right(tTrips)));

      sut(operadorId: tOperadorId);

      verify(
        () => mockRepo.watchTrips(operadorId: tOperadorId),
      ).called(1);
    });
  });
}
