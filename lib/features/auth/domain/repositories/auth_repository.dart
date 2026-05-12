import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/auth/domain/entities/operator_session.dart';

abstract interface class AuthRepository {
  Future<Either<AppError, OperatorSession>> login({
    required String employeeNumber,
    required String password,
  });

  Future<Either<AppError, Unit>> logout();

  Future<Either<AppError, OperatorSession>> getCurrentSession();

  Future<Either<AppError, Unit>> sendPasswordResetEmail({
    required String employeeNumber,
  });

  Stream<OperatorSession> watchAuthState();
}
