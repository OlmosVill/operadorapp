import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/auth/domain/entities/operator_session.dart';
import 'package:operadorapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:operadorapp/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase sut;
  late MockAuthRepository mockRepo;

  const tEmployeeNumber = '12345';
  const tPassword = 'secret123';
  const tSession = OperatorSession(
    operatorId: 'uid-001',
    employeeNumber: tEmployeeNumber,
    isAuthenticated: true,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    sut = LoginUseCase(mockRepo);
  });

  group('LoginUseCase —', () {
    test('retorna Right(session) con credenciales válidas', () async {
      when(
        () => mockRepo.login(
          employeeNumber: tEmployeeNumber,
          password: tPassword,
        ),
      ).thenAnswer((_) async => const Right(tSession));

      final result = await sut(
        employeeNumber: tEmployeeNumber,
        password: tPassword,
      );

      expect(result, const Right<AppError, OperatorSession>(tSession));
      verify(
        () => mockRepo.login(
          employeeNumber: tEmployeeNumber,
          password: tPassword,
        ),
      ).called(1);
    });

    test(
      'retorna ValidationError si el número de empleado está vacío',
      () async {
        final result = await sut(employeeNumber: '  ', password: tPassword);

        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error, isA<ValidationError>()),
          (_) => fail('Debería ser Left'),
        );
        verifyNever(
          () => mockRepo.login(
            employeeNumber: any(named: 'employeeNumber'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    test(
      'retorna ValidationError si la contraseña tiene menos de 6 caracteres',
      () async {
        final result = await sut(
          employeeNumber: tEmployeeNumber,
          password: '12345',
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (error) => expect(error, isA<ValidationError>()),
          (_) => fail('Debería ser Left'),
        );
        verifyNever(
          () => mockRepo.login(
            employeeNumber: any(named: 'employeeNumber'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    test('propaga el Left del repositorio tal cual', () async {
      const tError = AuthError(message: 'Credenciales incorrectas');
      when(
        () => mockRepo.login(
          employeeNumber: tEmployeeNumber,
          password: tPassword,
        ),
      ).thenAnswer((_) async => const Left(tError));

      final result = await sut(
        employeeNumber: tEmployeeNumber,
        password: tPassword,
      );

      expect(result, const Left<AppError, OperatorSession>(tError));
    });

    test(
      'trimea espacios del número de empleado antes de llamar al repositorio',
      () async {
        when(
          () => mockRepo.login(
            employeeNumber: tEmployeeNumber,
            password: tPassword,
          ),
        ).thenAnswer((_) async => const Right(tSession));

        await sut(
          employeeNumber: '  $tEmployeeNumber  ',
          password: tPassword,
        );

        verify(
          () => mockRepo.login(
            employeeNumber: tEmployeeNumber,
            password: tPassword,
          ),
        ).called(1);
      },
    );
  });
}
