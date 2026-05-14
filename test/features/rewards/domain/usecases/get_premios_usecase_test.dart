import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/domain/repositories/rewards_repository.dart';
import 'package:operadorapp/features/rewards/domain/usecases/get_premios_usecase.dart';

class MockRewardsRepository extends Mock implements RewardsRepository {}

void main() {
  late GetPremiosUsecase sut;
  late MockRewardsRepository mockRepo;

  final tPremios = [
    const Premio(
      id: 'premio-001',
      nombre: r'Tarjeta $500',
      tipo: PremioTipo.tarjetaRegalo,
      costoPuntos: 1000,
      activo: true,
    ),
  ];

  setUp(() {
    mockRepo = MockRewardsRepository();
    sut = GetPremiosUsecase(mockRepo);
  });

  group('GetPremiosUsecase —', () {
    test('emite Right(premios) cuando el repositorio emite datos', () {
      when(
        () => mockRepo.watchCatalogo(),
      ).thenAnswer(
        (_) => Stream.value(Right<AppError, List<Premio>>(tPremios)),
      );

      expect(
        sut.call(),
        emits(Right<AppError, List<Premio>>(tPremios)),
      );
    });

    test('emite Left(UnexpectedError) cuando el repositorio emite error', () {
      when(
        () => mockRepo.watchCatalogo(),
      ).thenAnswer(
        (_) => Stream.value(
          const Left<AppError, List<Premio>>(UnexpectedError()),
        ),
      );

      expect(
        sut.call(),
        emits(
          isA<Left<AppError, List<Premio>>>().having(
            (l) => l.value,
            'error',
            isA<UnexpectedError>(),
          ),
        ),
      );
    });

    test('emite Right([]) cuando el repositorio emite lista vacía', () {
      when(
        () => mockRepo.watchCatalogo(),
      ).thenAnswer(
        (_) => Stream.value(
          const Right<AppError, List<Premio>>([]),
        ),
      );

      expect(
        sut.call(),
        emits(
          isA<Right<AppError, List<Premio>>>()
              .having((r) => r.value, 'value', isEmpty),
        ),
      );
    });
  });
}
