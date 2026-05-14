import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';
import 'package:operadorapp/features/points/domain/repositories/points_repository.dart';
import 'package:operadorapp/features/points/domain/usecases/watch_movements_usecase.dart';

class MockPointsRepository extends Mock implements PointsRepository {}

void main() {
  late WatchMovementsUsecase sut;
  late MockPointsRepository mockRepo;

  const tOperadorId = 'operador-uuid-001';

  final tMovements = [
    PointMovement(
      id: 'mov-001',
      operadorId: tOperadorId,
      tipo: MovementType.ganadoViaje,
      puntos: 150,
      saldoDespues: 150,
      createdAt: DateTime(2025, 5, 10),
      descripcion: 'Viaje completado',
    ),
  ];

  setUp(() {
    mockRepo = MockPointsRepository();
    sut = WatchMovementsUsecase(mockRepo);
  });

  group('WatchMovementsUsecase —', () {
    test('retorna stream de Right(movements) desde el repositorio', () {
      when(
        () => mockRepo.watchMovimientos(tOperadorId),
      ).thenAnswer((_) => Stream.value(Right(tMovements)));

      final stream = sut(tOperadorId);

      expect(
        stream,
        emits(Right<AppError, List<PointMovement>>(tMovements)),
      );
    });

    test('propaga Left(error) del repositorio', () {
      const tError = NetworkError(message: 'Sin red');
      when(
        () => mockRepo.watchMovimientos(tOperadorId),
      ).thenAnswer(
        (_) => Stream.value(const Left(tError)),
      );

      final stream = sut(tOperadorId);

      expect(
        stream,
        emits(const Left<AppError, List<PointMovement>>(tError)),
      );
    });

    test('delega directamente al repositorio sin transformar', () {
      when(
        () => mockRepo.watchMovimientos(tOperadorId),
      ).thenAnswer((_) => Stream.value(Right(tMovements)));

      sut(tOperadorId);

      verify(() => mockRepo.watchMovimientos(tOperadorId)).called(1);
    });
  });
}
