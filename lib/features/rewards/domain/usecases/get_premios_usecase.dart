import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/domain/repositories/rewards_repository.dart';

class GetPremiosUsecase {
  const GetPremiosUsecase(this._repo);

  final RewardsRepository _repo;

  Stream<Either<AppError, List<Premio>>> call() => _repo.watchCatalogo();
}
