import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:logger/logger.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  SyncService({
    required AppDatabase db,
    required SupabaseClient supabase,
    required Logger logger,
  })  : _db = db,
        _supabase = supabase,
        _logger = logger;

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final Logger _logger;

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<void> syncProfile(String authUserId) async {
    try {
      final data = await _supabase
          .from('operadores')
          .select('*, puntos_operador(*)')
          .eq('auth_user_id', authUserId)
          .single();

      final puntos = data['puntos_operador'] as Map<String, dynamic>?;
      final fechaIngreso = data['fecha_ingreso'] as String;
      // Normalize to date-only string (Supabase may return full timestamp)
      final dateOnly = fechaIngreso.length > 10
          ? fechaIngreso.substring(0, 10)
          : fechaIngreso;

      await _db.profileDao.upsert(
        OperadoresTableCompanion(
          id: Value(data['id'] as String),
          authUserId: Value(authUserId),
          numeroEmpleado: Value(data['numero_empleado'] as String),
          nombreCompleto: Value(data['nombre_completo'] as String),
          email: Value(data['email'] as String?),
          telefono: Value(data['telefono'] as String?),
          fechaIngreso: Value(dateOnly),
          base: Value(data['base'] as String?),
          fotoPerfilUrl: Value(data['foto_perfil_url'] as String?),
          nivelActual:
              Value(data['nivel_actual'] as String? ?? 'plata'),
          puntosGanados:
              Value(puntos?['puntos_ganados'] as int? ?? 0),
          puntosCanjeados:
              Value(puntos?['puntos_canjeados'] as int? ?? 0),
          puntosDisponibles:
              Value(puntos?['puntos_disponibles'] as int? ?? 0),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      await _db.syncDao.setLastSyncAt('operadores', DateTime.now().toUtc());
      _logger.d('syncProfile completado para $authUserId');
    } on Exception catch (e) {
      _logger.w('syncProfile falló', error: e);
    }
  }

  // ─── Trips ────────────────────────────────────────────────────────────────

  Future<void> syncTrips(String operadorId) async {
    try {
      final since = await _db.tripsDao.getLastUpdatedAt(operadorId);
      var query = _supabase
          .from('viajes')
          .select()
          .eq('operador_id', operadorId);

      if (since != null) {
        query = query.gt('updated_at', since.toIso8601String());
      }

      final rows = await query.order('updated_at');

      if (rows.isEmpty) return;

      final companions = rows.map((r) {
        return ViajesTableCompanion(
          id: Value(r['id'] as String),
          operadorId: Value(r['operador_id'] as String),
          tractoId: Value(r['tracto_id'] as String?),
          origen: Value(r['origen'] as String),
          destino: Value(r['destino'] as String),
          origenLat: Value(_parseCoordLat(r['origen_coords'])),
          origenLng: Value(_parseCoordLng(r['origen_coords'])),
          destinoLat: Value(_parseCoordLat(r['destino_coords'])),
          destinoLng: Value(_parseCoordLng(r['destino_coords'])),
          fechaInicio: Value(_parseDateTime(r['fecha_inicio'])),
          fechaFin: Value(_parseDateTime(r['fecha_fin'])),
          kmEsperados:
              Value(_parseDouble(r['km_esperados'])),
          kmRecorridos:
              Value(_parseDouble(r['km_recorridos'])),
          litrosDiesel:
              Value(_parseDouble(r['litros_diesel'])),
          rendimientoReal:
              Value(_parseDouble(r['rendimiento_real'])),
          estado: Value(r['estado'] as String? ?? 'asignado'),
          calificacion: Value(_parseDouble(r['calificacion'])),
          puntosObtenidos:
              Value(r['puntos_obtenidos'] as int? ?? 0),
          notas: Value(r['notas'] as String?),
          createdAt: Value(
            _parseDateTime(r['created_at']) ?? DateTime.now().toUtc(),
          ),
          updatedAt: Value(
            _parseDateTime(r['updated_at']) ?? DateTime.now().toUtc(),
          ),
        );
      }).toList();

      await _db.tripsDao.upsertAll(companions);
      await _db.syncDao.setLastSyncAt('viajes', DateTime.now().toUtc());
      _logger.d('syncTrips: ${rows.length} viajes sincronizados');
    } on Exception catch (e) {
      _logger.w('syncTrips falló', error: e);
    }
  }

  Future<void> syncTripDetail(String viajeId) async {
    await Future.wait([
      _syncGpsPoints(viajeId),
      _syncIncidencias(viajeId),
      _syncAlertas(viajeId),
      _syncReportes(viajeId),
    ]);
  }

  Future<void> _syncGpsPoints(String viajeId) async {
    try {
      final rows = await _supabase
          .from('viaje_puntos_gps')
          .select(
            'id, viaje_id, coordenada, velocidad_kmh, '
            'rumbo_grados, altitud_m, timestamp_gps',
          )
          .eq('viaje_id', viajeId)
          .order('timestamp_gps');

      if (rows.isEmpty) return;

      final companions = rows
          .map((r) {
            final coords = _parseGeography(r['coordenada']);
            if (coords == null) return null;
            return GpsPuntosTableCompanion(
              id: Value(r['id'] as String),
              viajeId: Value(r['viaje_id'] as String),
              lat: Value(coords.$1),
              lng: Value(coords.$2),
              velocidadKmh: Value(_parseDouble(r['velocidad_kmh'])),
              rumboGrados: Value(_parseDouble(r['rumbo_grados'])),
              altitudM: Value(_parseDouble(r['altitud_m'])),
              timestampGps: Value(
                _parseDateTime(r['timestamp_gps']) ?? DateTime.now().toUtc(),
              ),
            );
          })
          .nonNulls
          .toList();

      await _db.tripsDao.upsertGpsPoints(companions);
    } on Exception catch (e) {
      _logger.w('_syncGpsPoints falló para $viajeId', error: e);
    }
  }

  Future<void> _syncIncidencias(String viajeId) async {
    try {
      final rows = await _supabase
          .from('incidencias')
          .select()
          .eq('viaje_id', viajeId)
          .order('timestamp_incidencia');

      if (rows.isEmpty) return;

      final companions = rows.map((r) {
        final coords = _parseGeography(r['coordenada']);
        return IncidenciasTableCompanion(
          id: Value(r['id'] as String),
          viajeId: Value(r['viaje_id'] as String),
          tipo: Value(r['tipo'] as String),
          descripcion: Value(r['descripcion'] as String?),
          severidad: Value(r['severidad'] as int?),
          lat: Value(coords?.$1),
          lng: Value(coords?.$2),
          timestampIncidencia: Value(
            _parseDateTime(r['timestamp_incidencia']) ?? DateTime.now().toUtc(),
          ),
          impactoPuntos: Value(r['impacto_puntos'] as int? ?? 0),
        );
      }).toList();

      await _db.tripsDao.upsertIncidencias(companions);
    } on Exception catch (e) {
      _logger.w('_syncIncidencias falló para $viajeId', error: e);
    }
  }

  Future<void> _syncAlertas(String viajeId) async {
    try {
      final rows = await _supabase
          .from('alertas_seguridad')
          .select()
          .eq('viaje_id', viajeId)
          .order('timestamp_alerta');

      if (rows.isEmpty) return;

      final companions = rows.map((r) {
        final coords = _parseGeography(r['coordenada']);
        return AlertasTableCompanion(
          id: Value(r['id'] as String),
          viajeId: Value(r['viaje_id'] as String),
          tipo: Value(r['tipo'] as String),
          valorMedido: Value(_parseDouble(r['valor_medido'])),
          umbralPermitido: Value(_parseDouble(r['umbral_permitido'])),
          lat: Value(coords?.$1),
          lng: Value(coords?.$2),
          timestampAlerta: Value(
            _parseDateTime(r['timestamp_alerta']) ?? DateTime.now().toUtc(),
          ),
          impactoPuntos: Value(r['impacto_puntos'] as int? ?? 0),
        );
      }).toList();

      await _db.tripsDao.upsertAlertas(companions);
    } on Exception catch (e) {
      _logger.w('_syncAlertas falló para $viajeId', error: e);
    }
  }

  Future<void> _syncReportes(String viajeId) async {
    try {
      final rows = await _supabase
          .from('reportes')
          .select()
          .eq('viaje_id', viajeId);

      if (rows.isEmpty) return;

      final companions = rows.map((r) {
        return ReportesTableCompanion(
          id: Value(r['id'] as String),
          viajeId: Value(r['viaje_id'] as String?),
          operadorId: Value(r['operador_id'] as String),
          tractoId: Value(r['tracto_id'] as String?),
          tipo: Value(r['tipo'] as String),
          estado: Value(r['estado'] as String? ?? 'abierto'),
          descripcion: Value(r['descripcion'] as String),
          lat: Value(_parseDouble(r['lat'])),
          lng: Value(_parseDouble(r['lng'])),
          fechaReporte: Value(
            _parseDateTime(r['fecha_reporte']) ?? DateTime.now().toUtc(),
          ),
          updatedAt: Value(
            _parseDateTime(r['updated_at']) ?? DateTime.now().toUtc(),
          ),
        );
      }).toList();

      await _db.tripsDao.upsertReportes(companions);
    } on Exception catch (e) {
      _logger.w('_syncReportes falló para $viajeId', error: e);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  // Parses Supabase GEOGRAPHY(POINT) in EWKB hex format.
  // Returns (lat, lng) or null if parsing fails.
  (double, double)? _parseGeography(Object? value) {
    if (value == null) return null;

    // PostgREST returns geography as hex-encoded EWKB.
    // Format: 01 (LE) + 01000020 (Point+SRID flag) + E6100000 (SRID 4326)
    // + X (lng, 8B) + Y (lat, 8B)
    if (value is String && value.length >= 50) {
      try {
        final bytes = Uint8List.fromList(
          List.generate(
            value.length ~/ 2,
            (i) => int.parse(value.substring(i * 2, i * 2 + 2), radix: 16),
          ),
        );
        // Skip 9 bytes: 1 (byte order) + 4 (type) + 4 (SRID)
        final data = ByteData.sublistView(bytes, 9);
        final lng = data.getFloat64(0, Endian.little);
        final lat = data.getFloat64(8, Endian.little);
        return (lat, lng);
      } on Exception {
        return null;
      }
    }

    // GeoJSON fallback: {"type":"Point","coordinates":[lng, lat]}
    if (value is Map<String, dynamic>) {
      final coords = value['coordinates'];
      if (coords is List && coords.length >= 2) {
        final lng = _parseDouble(coords[0]);
        final lat = _parseDouble(coords[1]);
        if (lat != null && lng != null) return (lat, lng);
      }
    }

    return null;
  }

  double? _parseCoordLat(Object? coords) => _parseGeography(coords)?.$1;
  double? _parseCoordLng(Object? coords) => _parseGeography(coords)?.$2;
}
