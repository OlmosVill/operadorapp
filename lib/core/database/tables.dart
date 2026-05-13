import 'package:drift/drift.dart';

// ─── Operadores ───────────────────────────────────────────────────────────────

@DataClassName('OperadorRow')
class OperadoresTable extends Table {
  TextColumn get id => text()();
  TextColumn get authUserId => text()();
  TextColumn get numeroEmpleado => text()();
  TextColumn get nombreCompleto => text()();
  TextColumn get email => text().nullable()();
  TextColumn get telefono => text().nullable()();
  // Stored as ISO 8601 date string (e.g. '2022-01-15')
  TextColumn get fechaIngreso => text()();
  TextColumn get base => text().nullable()();
  TextColumn get fotoPerfilUrl => text().nullable()();
  TextColumn get nivelActual =>
      text().withDefault(const Constant('plata'))();
  // Denormalized from puntos_operador — simpler for local reads
  IntColumn get puntosGanados =>
      integer().withDefault(const Constant(0))();
  IntColumn get puntosCanjeados =>
      integer().withDefault(const Constant(0))();
  IntColumn get puntosDisponibles =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Viajes ───────────────────────────────────────────────────────────────────

@DataClassName('ViajeRow')
class ViajesTable extends Table {
  TextColumn get id => text()();
  TextColumn get operadorId => text()();
  TextColumn get tractoId => text().nullable()();
  TextColumn get origen => text()();
  TextColumn get destino => text()();
  RealColumn get origenLat => real().nullable()();
  RealColumn get origenLng => real().nullable()();
  RealColumn get destinoLat => real().nullable()();
  RealColumn get destinoLng => real().nullable()();
  DateTimeColumn get fechaInicio => dateTime().nullable()();
  DateTimeColumn get fechaFin => dateTime().nullable()();
  RealColumn get kmEsperados => real().nullable()();
  RealColumn get kmRecorridos => real().nullable()();
  RealColumn get litrosDiesel => real().nullable()();
  RealColumn get rendimientoReal => real().nullable()();
  TextColumn get estado =>
      text().withDefault(const Constant('asignado'))();
  RealColumn get calificacion => real().nullable()();
  IntColumn get puntosObtenidos =>
      integer().withDefault(const Constant(0))();
  TextColumn get notas => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── GPS Points ───────────────────────────────────────────────────────────────

// lat/lng stored separately — Supabase GEOGRAPHY(POINT) is parsed on sync
@DataClassName('GpsPointRow')
class GpsPuntosTable extends Table {
  TextColumn get id => text()();
  TextColumn get viajeId => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get velocidadKmh => real().nullable()();
  RealColumn get rumboGrados => real().nullable()();
  RealColumn get altitudM => real().nullable()();
  DateTimeColumn get timestampGps => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Incidencias ──────────────────────────────────────────────────────────────

@DataClassName('IncidenciaRow')
class IncidenciasTable extends Table {
  TextColumn get id => text()();
  TextColumn get viajeId => text()();
  TextColumn get tipo => text()();
  TextColumn get descripcion => text().nullable()();
  IntColumn get severidad => integer().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  DateTimeColumn get timestampIncidencia => dateTime()();
  IntColumn get impactoPuntos =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Alertas de Seguridad ─────────────────────────────────────────────────────

@DataClassName('AlertaRow')
class AlertasTable extends Table {
  TextColumn get id => text()();
  TextColumn get viajeId => text()();
  TextColumn get tipo => text()();
  RealColumn get valorMedido => real().nullable()();
  RealColumn get umbralPermitido => real().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  DateTimeColumn get timestampAlerta => dateTime()();
  IntColumn get impactoPuntos =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Reportes ─────────────────────────────────────────────────────────────────

@DataClassName('ReporteRow')
class ReportesTable extends Table {
  TextColumn get id => text()();
  TextColumn get viajeId => text().nullable()();
  TextColumn get operadorId => text()();
  TextColumn get tractoId => text().nullable()();
  TextColumn get tipo => text()();
  TextColumn get estado =>
      text().withDefault(const Constant('abierto'))();
  TextColumn get descripcion => text()();
  // JSON-encoded list of photo URLs
  TextColumn get fotosUrls =>
      text().withDefault(const Constant('[]'))();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  DateTimeColumn get fechaReporte => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Premios Catálogo ─────────────────────────────────────────────────────────

@DataClassName('PremioRow')
class PremiosCatalogoTable extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get descripcion => text().nullable()();
  TextColumn get tipo => text()();
  IntColumn get costoPuntos => integer()();
  TextColumn get nivelMinimo => text().nullable()();
  TextColumn get imagenUrl => text().nullable()();
  IntColumn get stock => integer().nullable()();
  BoolColumn get activo =>
      boolean().withDefault(const Constant(true))();
  IntColumn get orden => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Premios Canjeados ────────────────────────────────────────────────────────

@DataClassName('CanjeRow')
class PremiosCanjeadosTable extends Table {
  TextColumn get id => text()();
  TextColumn get operadorId => text()();
  TextColumn get premioId => text()();
  IntColumn get puntosCanjeados => integer()();
  TextColumn get estado => text()();
  DateTimeColumn get fechaSolicitud => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Movimientos de Puntos ────────────────────────────────────────────────────

@DataClassName('MovimientoRow')
class MovimientosPuntosTable extends Table {
  TextColumn get id => text()();
  TextColumn get operadorId => text()();
  TextColumn get tipo => text()();
  IntColumn get puntos => integer()();
  TextColumn get viajeId => text().nullable()();
  TextColumn get canjeId => text().nullable()();
  TextColumn get descripcion => text().nullable()();
  IntColumn get saldoDespues => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Notificaciones In-App ────────────────────────────────────────────────────

@DataClassName('NotificacionRow')
class NotificacionesTable extends Table {
  TextColumn get id => text()();
  TextColumn get operadorId => text()();
  TextColumn get titulo => text()();
  TextColumn get mensaje => text()();
  TextColumn get tipo => text()();
  BoolColumn get leida =>
      boolean().withDefault(const Constant(false))();
  // JSON extra data
  TextColumn get datos => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─── Operaciones Pendientes (local-only) ─────────────────────────────────────

@DataClassName('PendingOpRow')
class PendingOpsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()();
  TextColumn get payload => text()();
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();
}

// ─── Metadatos de Sincronización (local-only) ────────────────────────────────

@DataClassName('SyncMetaRow')
class SyncMetadataTable extends Table {
  // 'tableName' is reserved by Drift for the SQL table name — use 'tableKey'
  TextColumn get tableKey => text()();
  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {tableKey};
}
