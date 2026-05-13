import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/features/trips/domain/entities/gps_point.dart';
import 'package:operadorapp/features/trips/domain/entities/security_alert.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_incident.dart';

abstract interface class TripsLocalDatasource {
  Stream<List<Trip>> watchTrips(String operadorId);

  Future<List<Trip>> getTrips(
    String operadorId, {
    int limit = 20,
    int offset = 0,
  });

  Future<Trip?> getTripById(String id);

  Future<List<GpsPoint>> getGpsPoints(String viajeId);

  Future<List<TripIncident>> getIncidents(String viajeId);

  Future<List<SecurityAlert>> getAlerts(String viajeId);
}

final class DriftTripsLocalDatasource implements TripsLocalDatasource {
  const DriftTripsLocalDatasource(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Trip>> watchTrips(String operadorId) =>
      _db.tripsDao.watchByOperador(operadorId).map(
            (rows) => rows.map(_rowToTrip).toList(),
          );

  @override
  Future<List<Trip>> getTrips(
    String operadorId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _db.tripsDao
        .getByOperador(operadorId, limit: limit, offset: offset);
    return rows.map(_rowToTrip).toList();
  }

  @override
  Future<Trip?> getTripById(String id) async {
    final row = await _db.tripsDao.getById(id);
    return row == null ? null : _rowToTrip(row);
  }

  @override
  Future<List<GpsPoint>> getGpsPoints(String viajeId) async {
    final rows = await _db.tripsDao.getGpsPoints(viajeId);
    return rows.map(_rowToGpsPoint).toList();
  }

  @override
  Future<List<TripIncident>> getIncidents(String viajeId) async {
    final rows = await _db.tripsDao.getIncidencias(viajeId);
    return rows.map(_rowToIncident).toList();
  }

  @override
  Future<List<SecurityAlert>> getAlerts(String viajeId) async {
    final rows = await _db.tripsDao.getAlertas(viajeId);
    return rows.map(_rowToAlert).toList();
  }

  // ─── Mappers ──────────────────────────────────────────────────────────────

  Trip _rowToTrip(ViajeRow r) => Trip(
        id: r.id,
        operadorId: r.operadorId,
        tractoId: r.tractoId,
        origen: r.origen,
        destino: r.destino,
        origenLat: r.origenLat,
        origenLng: r.origenLng,
        destinoLat: r.destinoLat,
        destinoLng: r.destinoLng,
        fechaInicio: r.fechaInicio,
        fechaFin: r.fechaFin,
        kmEsperados: r.kmEsperados,
        kmRecorridos: r.kmRecorridos,
        litrosDiesel: r.litrosDiesel,
        rendimientoReal: r.rendimientoReal,
        estado: TripStatusX.fromString(r.estado),
        calificacion: r.calificacion,
        puntosObtenidos: r.puntosObtenidos,
        notas: r.notas,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  GpsPoint _rowToGpsPoint(GpsPointRow r) => GpsPoint(
        id: r.id,
        viajeId: r.viajeId,
        lat: r.lat,
        lng: r.lng,
        velocidadKmh: r.velocidadKmh,
        rumboGrados: r.rumboGrados,
        altitudM: r.altitudM,
        timestampGps: r.timestampGps,
      );

  TripIncident _rowToIncident(IncidenciaRow r) => TripIncident(
        id: r.id,
        viajeId: r.viajeId,
        tipo: r.tipo,
        descripcion: r.descripcion,
        severidad: r.severidad,
        lat: r.lat,
        lng: r.lng,
        timestampIncidencia: r.timestampIncidencia,
        impactoPuntos: r.impactoPuntos,
      );

  SecurityAlert _rowToAlert(AlertaRow r) => SecurityAlert(
        id: r.id,
        viajeId: r.viajeId,
        tipo: r.tipo,
        valorMedido: r.valorMedido,
        umbralPermitido: r.umbralPermitido,
        lat: r.lat,
        lng: r.lng,
        timestampAlerta: r.timestampAlerta,
        impactoPuntos: r.impactoPuntos,
      );
}
