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
class TrucksDao extends DatabaseAccessor<AppDatabase> with _$TrucksDaoMixin {
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
                  t.tractoId.equals(tractoId) & t.operadorId.equals(operadorId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.fechaInicio)]))
          .get();

  // ─── Reportes por tracto ─────────────────────────────────────────────────

  Future<List<ReporteRow>> getReportesByTracto(String tractoId) =>
      (select(reportesTable)
            ..where((t) => t.tractoId.equals(tractoId))
            ..orderBy([(t) => OrderingTerm.desc(t.fechaReporte)]))
          .get();

  // ─── Reemplazos ──────────────────────────────────────────────────────────

  /// Deja los tractos locales iguales a los que ve el operador.
  ///
  /// No lleva filtro por operador porque la RLS ya limita `tractos` a los
  /// suyos (los de sus viajes y su historial), así que la tabla local se
  /// reemplaza entera. Sin esto quedan tractos de bases anteriores con `id`
  /// muertos, y el historial los muestra sin marca ni modelo.
  Future<void> replaceTractos(List<TractosTableCompanion> rows) =>
      transaction(() async {
        final ids = rows.map((r) => r.id.value).toList();
        final stale = delete(tractosTable);
        // `NOT IN ()` no es SQL válido: sin filas, se borra todo.
        if (ids.isNotEmpty) {
          stale.where((t) => t.id.isNotIn(ids));
        }
        await stale.go();
        if (rows.isEmpty) return;
        await batch((b) => b.insertAllOnConflictUpdate(tractosTable, rows));
      });

  /// Deja el historial local del operador igual al del servidor.
  Future<void> replaceHistorial(
    String operadorId,
    List<HistorialTractosTableCompanion> rows,
  ) =>
      transaction(() async {
        final ids = rows.map((r) => r.id.value).toList();
        final stale = delete(historialTractosTable)
          ..where((t) => t.operadorId.equals(operadorId));
        if (ids.isNotEmpty) {
          stale.where((t) => t.id.isNotIn(ids));
        }
        await stale.go();
        if (rows.isEmpty) return;
        await batch(
          (b) => b.insertAllOnConflictUpdate(historialTractosTable, rows),
        );
      });
}
