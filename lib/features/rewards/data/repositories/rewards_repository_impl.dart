import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/rewards/data/datasources/rewards_local_datasource.dart';
import 'package:operadorapp/features/rewards/data/datasources/rewards_remote_datasource.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/domain/repositories/rewards_repository.dart';

class RewardsRepositoryImpl implements RewardsRepository {
  const RewardsRepositoryImpl(this._local, this._remote);

  final RewardsLocalDatasource _local;
  final RewardsRemoteDatasource _remote;

  @override
  Stream<Either<AppError, List<Premio>>> watchCatalogo() async* {
    try {
      await for (final premios in _local.watchCatalogo()) {
        yield Right<AppError, List<Premio>>(premios);
      }
    } on Object catch (e) {
      yield Left<AppError, List<Premio>>(UnexpectedError(error: e));
    }
  }

  @override
  Stream<Either<AppError, List<Canje>>> watchCanjes(
    String operadorId,
  ) async* {
    try {
      await for (final canjes in _local.watchCanjes(operadorId)) {
        yield Right<AppError, List<Canje>>(canjes);
      }
    } on Object catch (e) {
      yield Left<AppError, List<Canje>>(UnexpectedError(error: e));
    }
  }

  @override
  Future<Either<AppError, Canje>> canjearPremio({
    required String premioId,
    required String operadorId,
  }) async {
    try {
      final canje = await _remote.canjearPremio(
        premioId: premioId,
        operadorId: operadorId,
      );
      await _local.upsertCanje(canje);
      return Right<AppError, Canje>(canje);
    } on Exception catch (e) {
      return Left<AppError, Canje>(UnexpectedError(error: e));
    }
  }
}
