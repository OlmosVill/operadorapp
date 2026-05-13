import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/auth/domain/entities/operator_session.dart';
import 'package:operadorapp/features/auth/domain/repositories/auth_repository.dart';

final class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppError, OperatorSession>> call({
    required String employeeNumber,
    required String password,
  }) {
    if (employeeNumber.trim().isEmpty) {
      return Future.value(
        const Left(ValidationError(message: 'Ingresa tu número de empleado')),
      );
    }
    if (password.length < 6) {
      return Future.value(
        const Left(
          ValidationError(
            message: 'La contraseña debe tener al menos 6 caracteres',
          ),
        ),
      );
    }

    return _repository.login(
      employeeNumber: employeeNumber.trim(),
      password: password,
    );
  }
}
