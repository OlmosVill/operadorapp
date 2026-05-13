import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:operadorapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRemoteDatasource extends Mock implements AuthRemoteDatasource {}

class MockLogger extends Mock implements Logger {}

class FakeAuthResponse extends Fake implements AuthResponse {
  FakeAuthResponse({this.user});
  @override
  final User? user;
}

class FakeUser extends Fake implements User {
  FakeUser({required this.id, this.email});
  @override
  final String id;
  @override
  final String? email;
}

void main() {
  late AuthRepositoryImpl sut;
  late MockAuthRemoteDatasource mockDatasource;
  late MockLogger mockLogger;

  const tEmployeeNumber = '12345';
  const tPassword = 'secret123';
  final tUser = FakeUser(
    id: 'uid-001',
    email: '$tEmployeeNumber@operadorapp.internal',
  );

  setUp(() {
    mockDatasource = MockAuthRemoteDatasource();
    mockLogger = MockLogger();
    sut = AuthRepositoryImpl(
      remoteDatasource: mockDatasource,
      logger: mockLogger,
    );
  });

  group('AuthRepositoryImpl.login —', () {
    test(
      'retorna Right(session) cuando datasource responde con user',
      () async {
        when(
          () => mockDatasource.signIn(
            employeeNumber: tEmployeeNumber,
            password: tPassword,
          ),
        ).thenAnswer((_) async => FakeAuthResponse(user: tUser));

        final result = await sut.login(
          employeeNumber: tEmployeeNumber,
          password: tPassword,
        );

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Debería ser Right'),
          (session) {
            expect(session.operatorId, 'uid-001');
            expect(session.employeeNumber, tEmployeeNumber);
            expect(session.isAuthenticated, isTrue);
          },
        );
      },
    );

    test('retorna AuthError si el datasource devuelve user null', () async {
      when(
        () => mockDatasource.signIn(
          employeeNumber: tEmployeeNumber,
          password: tPassword,
        ),
      ).thenAnswer((_) async => FakeAuthResponse());

      final result = await sut.login(
        employeeNumber: tEmployeeNumber,
        password: tPassword,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<AuthError>()),
        (_) => fail('Debería ser Left'),
      );
    });

    test('mapea AuthException a AuthError con mensaje en español', () async {
      when(
        () => mockDatasource.signIn(
          employeeNumber: tEmployeeNumber,
          password: tPassword,
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      final result = await sut.login(
        employeeNumber: tEmployeeNumber,
        password: tPassword,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) {
          expect(error, isA<AuthError>());
          final authError = error as AuthError;
          expect(authError.message, contains('Número de empleado'));
        },
        (_) => fail('Debería ser Left'),
      );
    });

    test('mapea excepciones inesperadas a UnexpectedError', () async {
      when(
        () => mockDatasource.signIn(
          employeeNumber: tEmployeeNumber,
          password: tPassword,
        ),
      ).thenThrow(Exception('network failure'));

      final result = await sut.login(
        employeeNumber: tEmployeeNumber,
        password: tPassword,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error, isA<UnexpectedError>()),
        (_) => fail('Debería ser Left'),
      );
    });
  });

  group('AuthRepositoryImpl.logout —', () {
    test('retorna Right(unit) en éxito', () async {
      when(() => mockDatasource.signOut()).thenAnswer((_) async {});

      final result = await sut.logout();

      expect(result, const Right<AppError, Unit>(unit));
    });

    test('retorna UnexpectedError si signOut lanza excepción', () async {
      when(() => mockDatasource.signOut()).thenThrow(Exception('network'));

      final result = await sut.logout();

      expect(result.isLeft(), isTrue);
    });
  });
}
