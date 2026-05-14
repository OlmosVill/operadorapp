import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';

abstract interface class RewardsRepository {
  Stream<Either<AppError, List<Premio>>> watchCatalogo();

  Stream<Either<AppError, List<Canje>>> watchCanjes(String operadorId);

  Future<Either<AppError, Canje>> canjearPremio({
    required String premioId,
    required String operadorId,
  });
}
