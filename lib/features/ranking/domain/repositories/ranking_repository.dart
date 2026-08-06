import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';

abstract class RankingRepository {
  Stream<Either<AppError, List<RankingEntry>>> watchRanking(
    RankingPeriodo periodo,
  );

  /// Fuerza una lectura remota (pull-to-refresh).
  Future<Either<AppError, void>> refresh(RankingPeriodo periodo);
}
