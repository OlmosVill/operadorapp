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

  /// Deja los viajes locales del operador iguales a los del servidor.
  ///
  /// Además arrastra las tablas hijas: Drift no declara FKs, así que no hay
  /// `ON DELETE CASCADE` y los puntos GPS, incidencias y alertas de un viaje
  /// que ya no existe se quedarían como basura que nadie vuelve a leer.
  Future<void> replaceViajes(
    String operadorId,
    List<ViajesTableCompanion> rows,
  ) =>
      transaction(() async {
        final ids = rows.map((r) => r.id.value).toList();
        final query = select(viajesTable)
          ..where((t) => t.operadorId.equals(operadorId));
        // `NOT IN ()` no es SQL válido: sin filas, se borra todo lo suyo.
        if (ids.isNotEmpty) {
          query.where((t) => t.id.isNotIn(ids));
        }
        final obsoletos = await query.map((row) => row.id).get();

        if (obsoletos.isNotEmpty) {
          await (delete(gpsPuntosTable)
                ..where((t) => t.viajeId.isIn(obsoletos)))
              .go();
          await (delete(incidenciasTable)
                ..where((t) => t.viajeId.isIn(obsoletos)))
              .go();
          await (delete(alertasTable)..where((t) => t.viajeId.isIn(obsoletos)))
              .go();
          await (delete(viajesTable)..where((t) => t.id.isIn(obsoletos))).go();
        }

        if (rows.isEmpty) return;
        await batch((b) => b.insertAllOnConflictUpdate(viajesTable, rows));
      });

  // ─── GPS Points ──────────────────────────────────────────────────────────

  Future<List<GpsPointRow>> getGpsPoints(String viajeId) =>
      (select(gpsPuntosTable)
            ..where((t) => t.viajeId.equals(viajeId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestampGps)]))
          .get();

  /// Deja los puntos GPS locales del viaje iguales a los del servidor.
  ///
  /// A diferencia de los reemplazos por operador, aquí no se arma lista de
  /// `id`: el servidor manda el set completo del viaje, y un viaje largo trae
  /// miles de puntos, uno por variable enlazada (`SQLITE_MAX_VARIABLE_NUMBER`).
  /// Sale más barato borrar la rebanada del viaje y reinsertarla.
  Future<void> replaceGpsPoints(
    String viajeId,
    List<GpsPuntosTableCompanion> rows,
  ) =>
      transaction(() async {
        await (delete(gpsPuntosTable)..where((t) => t.viajeId.equals(viajeId)))
            .go();
        await batch((b) => b.insertAll(gpsPuntosTable, rows));
      });

  // ─── Incidencias ─────────────────────────────────────────────────────────

  Future<List<IncidenciaRow>> getIncidencias(String viajeId) =>
      (select(incidenciasTable)
            ..where((t) => t.viajeId.equals(viajeId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestampIncidencia)]))
          .get();

  /// Mismo criterio que [replaceGpsPoints], por viaje.
  Future<void> replaceIncidencias(
    String viajeId,
    List<IncidenciasTableCompanion> rows,
  ) =>
      transaction(() async {
        await (delete(incidenciasTable)
              ..where((t) => t.viajeId.equals(viajeId)))
            .go();
        await batch((b) => b.insertAll(incidenciasTable, rows));
      });

  // ─── Alertas ─────────────────────────────────────────────────────────────

  Future<List<AlertaRow>> getAlertas(String viajeId) => (select(alertasTable)
        ..where((t) => t.viajeId.equals(viajeId))
        ..orderBy([(t) => OrderingTerm.asc(t.timestampAlerta)]))
      .get();

  /// Mismo criterio que [replaceGpsPoints], por viaje.
  Future<void> replaceAlertas(
    String viajeId,
    List<AlertasTableCompanion> rows,
  ) =>
      transaction(() async {
        await (delete(alertasTable)..where((t) => t.viajeId.equals(viajeId)))
            .go();
        await batch((b) => b.insertAll(alertasTable, rows));
      });

  // ─── Reportes ────────────────────────────────────────────────────────────

  Future<List<ReporteRow>> getReportesByViaje(String viajeId) =>
      (select(reportesTable)..where((t) => t.viajeId.equals(viajeId))).get();

  /// Mismo criterio que [replaceGpsPoints], por viaje.
  Future<void> replaceReportesByViaje(
    String viajeId,
    List<ReportesTableCompanion> rows,
  ) =>
      transaction(() async {
        await (delete(reportesTable)..where((t) => t.viajeId.equals(viajeId)))
            .go();
        await batch((b) => b.insertAll(reportesTable, rows));
      });

  /// Deja los reportes locales del operador iguales a los del servidor.
  ///
  /// Los reportes sin viaje sólo los alcanza este barrido, que además cubre
  /// lo que escribe [replaceReportesByViaje]: todo reporte de un viaje del
  /// operador vuelve también en la consulta por operador.
  Future<void> replaceReportesByOperador(
    String operadorId,
    List<ReportesTableCompanion> rows,
  ) =>
      transaction(() async {
        final ids = rows.map((r) => r.id.value).toList();
        final stale = delete(reportesTable)
          ..where((t) => t.operadorId.equals(operadorId));
        // `NOT IN ()` no es SQL válido: sin filas, se borra todo lo suyo.
        if (ids.isNotEmpty) {
          stale.where((t) => t.id.isNotIn(ids));
        }
        await stale.go();
        if (rows.isEmpty) return;
        await batch((b) => b.insertAllOnConflictUpdate(reportesTable, rows));
      });
}
