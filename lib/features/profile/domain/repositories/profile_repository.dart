import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';

abstract interface class ProfileRepository {
  Future<Either<AppError, OperatorProfile>> getProfile({
    required String authUserId,
  });

  Stream<Either<AppError, OperatorProfile>> watchProfile({
    required String authUserId,
  });
}
