import 'package:drift/drift.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/tables.dart';

part 'trucks_dao.g.dart';

@DriftAccessor(
  tables: [
    TractosTable,
    HistorialTractosTable,
    ViajesTable,
    ReportesTable,
  ],
)
class TrucksDao extends DatabaseAccessor<AppDatabase>
    with _$TrucksDaoMixin {
  TrucksDao(AppDatabase db) : super(db);

  // ─── Historial + Tracto (join) ───────────────────────────────────────────

  Stream<List<(HistorialTractoRow, TractoRow?)>> watchByOperador(
    String operadorId,
  ) {
    final query = select(historialTractosTable).join([
      leftOuterJoin(
        tractosTable,
        tractosTable.id.equalsExp(historialTractosTable.tractoId),
      ),
    ])
      ..where(historialTractosTable.operadorId.equals(operadorId))
      ..orderBy([
        OrderingTerm.desc(historialTractosTable.esActual),
        OrderingTerm.desc(historialTractosTable.fechaInicio),
      ]);
    return query.watch().map(
          (rows) => rows
              .map(
                (r) => (
                  r.readTable(historialTractosTable),
                  r.readTableOrNull(tractosTable),
                ),
              )
              .toList(),
        );
  }

  // ─── Viajes por tracto ───────────────────────────────────────────────────

  Future<List<ViajeRow>> getViajesByTracto(
    String tractoId,
    String operadorId,
  ) =>
      (select(viajesTable)
            ..where(
              (t) =>
                  t.tractoId.equals(tractoId) &
                  t.operadorId.equals(operadorId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.fechaInicio)]))
          .get();

  // ─── Reportes por tracto ─────────────────────────────────────────────────

  Future<List<ReporteRow>> getReportesByTracto(String tractoId) =>
      (select(reportesTable)
            ..where((t) => t.tractoId.equals(tractoId))
            ..orderBy([(t) => OrderingTerm.desc(t.fechaReporte)]))
          .get();

  // ─── Upserts ─────────────────────────────────────────────────────────────

  Future<void> upsertTractos(List<TractosTableCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(tractosTable, rows));

  Future<void> upsertHistorial(
    List<HistorialTractosTableCompanion> rows,
  ) =>
      batch(
        (b) => b.insertAllOnConflictUpdate(historialTractosTable, rows),
      );

  Future<DateTime?> getLastHistorialUpdatedAt(String operadorId) async {
    final query = select(historialTractosTable)
      ..where((t) => t.operadorId.equals(operadorId))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.updatedAt;
  }

  Future<DateTime?> getLastTractoUpdatedAt() async {
    final query = select(tractosTable)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.updatedAt;
  }
}
