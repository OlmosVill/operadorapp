import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/points/data/datasources/points_local_datasource.dart';
import 'package:operadorapp/features/points/data/repositories/points_repository_impl.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';

class MockPointsLocalDatasource extends Mock implements PointsLocalDatasource {}

void main() {
  late PointsRepositoryImpl sut;
  late MockPointsLocalDatasource mockLocal;

  const tOperadorId = 'operador-uuid-001';

  final tMovements = [
    PointMovement(
      id: 'mov-001',
      operadorId: tOperadorId,
      tipo: MovementType.ganadoViaje,
      puntos: 200,
      saldoDespues: 200,
      createdAt: DateTime(2025, 6),
    ),
  ];

  setUp(() {
    mockLocal = MockPointsLocalDatasource();
    sut = PointsRepositoryImpl(mockLocal);
  });

  group('PointsRepositoryImpl.watchMovimientos —', () {
    test('emite Right(movements) cuando el datasource emite datos', () {
      when(
        () => mockLocal.watchMovimientos(tOperadorId),
      ).thenAnswer((_) => Stream.value(tMovements));

      expect(
        sut.watchMovimientos(tOperadorId),
        emits(Right<AppError, List<PointMovement>>(tMovements)),
      );
    });

    test('emite Left(UnexpectedError) cuando el datasource lanza excepción',
        () {
      when(
        () => mockLocal.watchMovimientos(tOperadorId),
      ).thenAnswer((_) => Stream.error(Exception('DB error')));

      expect(
        sut.watchMovimientos(tOperadorId),
        emits(
          isA<Left<AppError, List<PointMovement>>>().having(
            (l) => l.value,
            'error',
            isA<UnexpectedError>(),
          ),
        ),
      );
    });

    test('emite Right([]) cuando el datasource emite lista vacía', () {
      when(
        () => mockLocal.watchMovimientos(tOperadorId),
      ).thenAnswer((_) => Stream.value([]));

      expect(
        sut.watchMovimientos(tOperadorId),
        emits(
          isA<Right<AppError, List<PointMovement>>>()
              .having((r) => r.value, 'value', isEmpty),
        ),
      );
    });
  });
}
