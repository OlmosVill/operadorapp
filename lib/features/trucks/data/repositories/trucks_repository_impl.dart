import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/daos/trucks_dao.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/core/services/sync_service.dart';
import 'package:operadorapp/features/trucks/domain/entities/truck.dart';
import 'package:operadorapp/features/trucks/domain/repositories/trucks_repository.dart';

class TrucksRepositoryImpl implements TrucksRepository {
  const TrucksRepositoryImpl(this._dao, this._sync);

  final TrucksDao _dao;
  final SyncService _sync;

  @override
  Stream<Either<AppError, List<TruckSummary>>> watchByOperador(
    String operadorId,
  ) async* {
    unawaited(_sync.syncTractos());
    unawaited(_sync.syncHistorialTractos(operadorId));
    try {
      await for (final pairs in _dao.watchByOperador(operadorId)) {
        yield Right<AppError, List<TruckSummary>>(
          pairs.map((p) => _mapToSummary(p.$1, p.$2)).toList(),
        );
      }
    } on Object catch (e) {
      yield Left<AppError, List<TruckSummary>>(
        UnexpectedError(error: e),
      );
    }
  }

  @override
  Future<Either<AppError, List<TruckReport>>> getReportes(
    String tractoId,
  ) async {
    try {
      final rows = await _dao.getReportesByTracto(tractoId);
      return Right<AppError, List<TruckReport>>(
        rows.map<TruckReport>(_mapToReport).toList(),
      );
    } on Object catch (e) {
      return Left<AppError, List<TruckReport>>(UnexpectedError(error: e));
    }
  }

  @override
  Future<Either<AppError, double?>> getRendimientoPromedio(
    String tractoId,
    String operadorId,
  ) async {
    try {
      final viajes = await _dao.getViajesByTracto(tractoId, operadorId);
      final vals =
          viajes.map((v) => v.rendimientoReal).whereType<double>().toList();
      if (vals.isEmpty) {
        return const Right<AppError, double?>(null);
      }
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      return Right<AppError, double?>(avg);
    } on Object catch (e) {
      return Left<AppError, double?>(UnexpectedError(error: e));
    }
  }

  // ─── Mappers ─────────────────────────────────────────────────────────────

  TruckSummary _mapToSummary(HistorialTractoRow h, TractoRow? t) =>
      TruckSummary(
        tractoId: h.tractoId,
        historialId: h.id,
        numeroEconomico: t?.numeroEconomico ?? h.tractoId,
        marca: t?.marca,
        modelo: t?.modelo,
        anio: t?.anio,
        placa: t?.placa,
        rendimientoEsperado: t?.rendimientoEsperado,
        kmRecorridos: h.kmRecorridos,
        viajesRealizados: h.viajesRealizados,
        calificacionPromedio: h.calificacionPromedio,
        esActual: h.esActual,
        fechaInicio: h.fechaInicio,
        fechaFin: h.fechaFin,
      );

  TruckReport _mapToReport(ReporteRow r) => TruckReport(
        id: r.id,
        tipo: r.tipo,
        estado: r.estado,
        descripcion: r.descripcion,
        fechaReporte: r.fechaReporte,
      );
}
