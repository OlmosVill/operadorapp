import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/daos/ranking_dao.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/core/services/sync_service.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';
import 'package:operadorapp/features/ranking/domain/repositories/ranking_repository.dart';

class RankingRepositoryImpl implements RankingRepository {
  const RankingRepositoryImpl(this._dao, this._sync);

  final RankingDao _dao;
  final SyncService _sync;

  @override
  Stream<Either<AppError, List<RankingEntry>>> watchRanking(
    RankingPeriodo periodo,
  ) async* {
    unawaited(_sync.syncRanking(periodo.value));
    try {
      await for (final rows in _dao.watchByPeriodo(periodo.value)) {
        yield Right<AppError, List<RankingEntry>>(
          rows.map(_mapToEntry).toList(),
        );
      }
    } on Object catch (e) {
      yield Left<AppError, List<RankingEntry>>(UnexpectedError(error: e));
    }
  }

  @override
  Future<Either<AppError, void>> refresh(RankingPeriodo periodo) async {
    try {
      await _sync.syncRanking(periodo.value);
      return const Right<AppError, void>(null);
    } on Object catch (e) {
      return Left<AppError, void>(UnexpectedError(error: e));
    }
  }

  RankingEntry _mapToEntry(RankingRow r) => RankingEntry(
        operadorId: r.operadorId,
        numeroEmpleado: r.numeroEmpleado,
        nombreCompleto: r.nombreCompleto,
        nivel: OperatorLevelX.fromString(r.nivel),
        puntos: r.puntos,
        viajesCompletados: r.viajesCompletados,
        posicion: r.posicion,
        calificacion: r.calificacion,
        fotoPerfilUrl: r.fotoPerfilUrl,
        posicionAnterior: r.posicionAnterior,
      );
}
