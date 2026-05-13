import 'package:drift/drift.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/tables.dart';

part 'trips_dao.g.dart';

@DriftAccessor(
  tables: [
    ViajesTable,
    GpsPuntosTable,
    IncidenciasTable,
    AlertasTable,
    ReportesTable,
  ],
)
class TripsDao extends DatabaseAccessor<AppDatabase> with _$TripsDaoMixin {
  TripsDao(AppDatabase db) : super(db);

  // ─── Viajes ───────────────────────────────────────────────────────────────

  Stream<List<ViajeRow>> watchByOperador(String operadorId) =>
      (select(viajesTable)
            ..where((t) => t.operadorId.equals(operadorId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<List<ViajeRow>> getByOperador(
    String operadorId, {
    int limit = 20,
    int offset = 0,
  }) =>
      (select(viajesTable)
            ..where((t) => t.operadorId.equals(operadorId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<ViajeRow?> getById(String id) =>
      (select(viajesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<DateTime?> getLastUpdatedAt(String operadorId) async {
    final query = select(viajesTable)
      ..where((t) => t.operadorId.equals(operadorId))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.updatedAt;
  }

  Future<void> upsertAll(List<ViajesTableCompanion> rows) => batch(
        (b) => b.insertAllOnConflictUpdate(viajesTable, rows),
      );

  // ─── GPS Points ─────────────────────────────────────────────────────────────

  Future<List<GpsPointRow>> getGpsPoints(String viajeId) =>
      (select(gpsPuntosTable)
            ..where((t) => t.viajeId.equals(viajeId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestampGps)]))
          .get();

  Future<void> upsertGpsPoints(List<GpsPuntosTableCompanion> rows) => batch(
        (b) => b.insertAllOnConflictUpdate(gpsPuntosTable, rows),
      );

  // ─── Incidencias ────────────────────────────────────────────────────────────

  Future<List<IncidenciaRow>> getIncidencias(String viajeId) =>
      (select(incidenciasTable)
            ..where((t) => t.viajeId.equals(viajeId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestampIncidencia)]))
          .get();

  Future<void> upsertIncidencias(List<IncidenciasTableCompanion> rows) => batch(
        (b) => b.insertAllOnConflictUpdate(incidenciasTable, rows),
      );

  // ─── Alertas ────────────────────────────────────────────────────────────────

  Future<List<AlertaRow>> getAlertas(String viajeId) =>
      (select(alertasTable)
            ..where((t) => t.viajeId.equals(viajeId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestampAlerta)]))
          .get();

  Future<void> upsertAlertas(List<AlertasTableCompanion> rows) => batch(
        (b) => b.insertAllOnConflictUpdate(alertasTable, rows),
      );

  // ─── Reportes ───────────────────────────────────────────────────────────────

  Future<List<ReporteRow>> getReportesByViaje(String viajeId) =>
      (select(reportesTable)
            ..where((t) => t.viajeId.equals(viajeId)))
          .get();

  Future<void> upsertReportes(List<ReportesTableCompanion> rows) => batch(
        (b) => b.insertAllOnConflictUpdate(reportesTable, rows),
      );
}
