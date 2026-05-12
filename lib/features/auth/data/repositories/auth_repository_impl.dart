import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:operadorapp/features/auth/domain/entities/operator_session.dart';
import 'package:operadorapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDatasource remoteDatasource,
    required Logger logger,
  })  : _remote = remoteDatasource,
        _logger = logger;

  final AuthRemoteDatasource _remote;
  final Logger _logger;

  @override
  Future<Either<AppError, OperatorSession>> login({
    required String employeeNumber,
    required String password,
  }) async {
    try {
      final response = await _remote.signIn(
        employeeNumber: employeeNumber,
        password: password,
      );

      if (response.user == null) {
        return const Left(AuthError(message: 'Credenciales incorrectas'));
      }

      return Right(
        OperatorSession(
          operatorId: response.user!.id,
          employeeNumber: employeeNumber,
          isAuthenticated: true,
        ),
      );
    } on AuthException catch (e) {
      _logger.w('Auth error', error: e.message);
      return Left(AuthError(message: _mapAuthMessage(e.message)));
    } catch (e, st) {
      _logger.e('Unexpected login error', error: e, stackTrace: st);
      return Left(UnexpectedError(error: e, stackTrace: st));
    }
  }

  @override
  Future<Either<AppError, Unit>> logout() async {
    try {
      await _remote.signOut();
      return const Right(unit);
    } catch (e, st) {
      _logger.e('Logout error', error: e, stackTrace: st);
      return Left(UnexpectedError(error: e, stackTrace: st));
    }
  }

  @override
  Future<Either<AppError, OperatorSession>> getCurrentSession() async {
    final session = _remote.getCurrentSession();
    if (session == null) {
      return Right(OperatorSession.unauthenticated());
    }
    final employeeNumber = _emailToEmployeeNumber(session.user.email ?? '');
    return Right(
      OperatorSession(
        operatorId: session.user.id,
        employeeNumber: employeeNumber,
        isAuthenticated: true,
      ),
    );
  }

  @override
  Future<Either<AppError, Unit>> sendPasswordResetEmail({
    required String employeeNumber,
  }) async {
    try {
      await _remote.sendPasswordResetEmail(employeeNumber: employeeNumber);
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthError(message: _mapAuthMessage(e.message)));
    } catch (e, st) {
      return Left(UnexpectedError(error: e, stackTrace: st));
    }
  }

  @override
  Stream<OperatorSession> watchAuthState() {
    return _remote.watchAuthState().map((state) {
      final user = state.session?.user;
      if (user == null) return OperatorSession.unauthenticated();
      return OperatorSession(
        operatorId: user.id,
        employeeNumber: _emailToEmployeeNumber(user.email ?? ''),
        isAuthenticated: true,
      );
    });
  }

  String _emailToEmployeeNumber(String email) => email.split('@').first;

  String _mapAuthMessage(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'Número de empleado o contraseña incorrectos';
    }
    if (raw.contains('Too many requests')) {
      return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Tu cuenta no está activa. Contacta a RH.';
    }
    return 'Error al iniciar sesión. Intenta de nuevo.';
  }
}
