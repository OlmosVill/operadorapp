import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/domain/repositories/rewards_repository.dart';

class CanjearUsecase {
  const CanjearUsecase(this._repo);

  final RewardsRepository _repo;

  Future<Either<AppError, Canje>> call({
    required String premioId,
    required String operadorId,
  }) =>
      _repo.canjearPremio(premioId: premioId, operadorId: operadorId);
}
