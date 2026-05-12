import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/domain/repositories/profile_repository.dart';

final class GetProfileUseCase {
  const GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<AppError, OperatorProfile>> call({
    required String authUserId,
  }) {
    if (authUserId.isEmpty) {
      return Future.value(
        const Left(AuthError(message: 'Sesión inválida. Inicia sesión de nuevo.')),
      );
    }
    return _repository.getProfile(authUserId: authUserId);
  }
}
