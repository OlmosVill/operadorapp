import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  const tOperador = 'operador-uuid-001';
  const tOtroOperador = 'operador-uuid-002';
  const tViaje = 'viaje-001';
  final tFecha = DateTime.utc(2026, 8);

  ViajesTableCompanion viaje(
    String id, {
    String operadorId = tOperador,
    String destino = 'Monterrey',
  }) =>
      ViajesTableCompanion(
        id: Value(id),
        operadorId: Value(operadorId),
        origen: const Value('CDMX'),
        destino: Value(destino),
        createdAt: Value(tFecha),
        updatedAt: Value(tFecha),
      );

  GpsPuntosTableCompanion punto(String id, {String viajeId = tViaje}) =>
      GpsPuntosTableCompanion(
        id: Value(id),
        viajeId: Value(viajeId),
        lat: const Value(19.4),
        lng: const Value(-99.1),
        timestampGps: Value(tFecha),
      );

  IncidenciasTableCompanion incidencia(String id, {String viajeId = tViaje}) =>
      IncidenciasTableCompanion(
        id: Value(id),
        viajeId: Value(viajeId),
        tipo: const Value('frenado_brusco'),
        timestampIncidencia: Value(tFecha),
      );

  AlertasTableCompanion alerta(String id, {String viajeId = tViaje}) =>
      AlertasTableCompanion(
        id: Value(id),
        viajeId: Value(viajeId),
        tipo: const Value('exceso_velocidad'),
        timestampAlerta: Value(tFecha),
      );

  ReportesTableCompanion reporte(
    String id, {
    String operadorId = tOperador,
    String descripcion = 'Falla de frenos',
    String? viajeId,
  }) =>
      ReportesTableCompanion(
        id: Value(id),
        viajeId: Value(viajeId),
        operadorId: Value(operadorId),
        tipo: const Value('mecanico'),
        descripcion: Value(descripcion),
        fechaReporte: Value(tFecha),
        updatedAt: Value(tFecha),
      );

  Future<List<String>> viajeIds() async {
    final rows = await db.select(db.viajesTable).get();
    return rows.map((r) => r.id).toList()..sort();
  }

  Future<List<String>> reporteIds() async {
    final rows = await db.select(db.reportesTable).get();
    return rows.map((r) => r.id).toList()..sort();
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TripsDao.replaceViajes —', () {
    test('borra los viajes que ya no vienen del servidor', () async {
      await db.tripsDao.replaceViajes(
        tOperador,
        [viaje('viejo-1'), viaje('viejo-2')],
      );

      await db.tripsDao.replaceViajes(tOperador, [viaje('nuevo-1')]);

      expect(await viajeIds(), ['nuevo-1']);
    });

    test('actualiza los viajes que siguen viniendo', () async {
      await db.tripsDao.replaceViajes(tOperador, [viaje('v1')]);

      await db.tripsDao
          .replaceViajes(tOperador, [viaje('v1', destino: 'Saltillo')]);

      final rows = await db.select(db.viajesTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.destino, 'Saltillo');
    });

    test('no toca los viajes de otro operador', () async {
      await db.tripsDao.replaceViajes(
        tOtroOperador,
        [viaje('otro-1', operadorId: tOtroOperador)],
      );

      await db.tripsDao.replaceViajes(tOperador, [viaje('v1')]);

      expect(await viajeIds(), unorderedEquals(['v1', 'otro-1']));
    });

    test('con lista vacía borra solo lo del operador', () async {
      await db.tripsDao.replaceViajes(tOperador, [viaje('v1')]);
      await db.tripsDao.replaceViajes(
        tOtroOperador,
        [viaje('otro-1', operadorId: tOtroOperador)],
      );

      await db.tripsDao.replaceViajes(tOperador, []);

      expect(await viajeIds(), ['otro-1']);
    });

    test('arrastra gps, incidencias y alertas del viaje borrado', () async {
      await db.tripsDao.replaceViajes(tOperador, [viaje(tViaje)]);
      await db.tripsDao.replaceGpsPoints(tViaje, [punto('g1')]);
      await db.tripsDao.replaceIncidencias(tViaje, [incidencia('i1')]);
      await db.tripsDao.replaceAlertas(tViaje, [alerta('a1')]);

      await db.tripsDao.replaceViajes(tOperador, [viaje('otro-viaje')]);

      expect(await db.tripsDao.getGpsPoints(tViaje), isEmpty);
      expect(await db.tripsDao.getIncidencias(tViaje), isEmpty);
      expect(await db.tripsDao.getAlertas(tViaje), isEmpty);
    });

    test('conserva las hijas de los viajes que siguen vivos', () async {
      await db.tripsDao.replaceViajes(tOperador, [viaje(tViaje)]);
      await db.tripsDao.replaceGpsPoints(tViaje, [punto('g1')]);

      await db.tripsDao.replaceViajes(tOperador, [viaje(tViaje)]);

      expect(await db.tripsDao.getGpsPoints(tViaje), hasLength(1));
    });
  });

  group('TripsDao — hijas del viaje', () {
    test('replaceGpsPoints borra los puntos que ya no vienen', () async {
      await db.tripsDao
          .replaceGpsPoints(tViaje, [punto('viejo-1'), punto('viejo-2')]);

      await db.tripsDao.replaceGpsPoints(tViaje, [punto('nuevo-1')]);

      final rows = await db.tripsDao.getGpsPoints(tViaje);
      expect(rows.map((r) => r.id), ['nuevo-1']);
    });

    test('replaceGpsPoints no toca los puntos de otro viaje', () async {
      await db.tripsDao.replaceGpsPoints(
        'viaje-002',
        [punto('otro-1', viajeId: 'viaje-002')],
      );

      await db.tripsDao.replaceGpsPoints(tViaje, [punto('g1')]);

      expect(await db.tripsDao.getGpsPoints('viaje-002'), hasLength(1));
    });

    test('replaceGpsPoints con lista vacía vacía el viaje', () async {
      await db.tripsDao.replaceGpsPoints(tViaje, [punto('g1')]);

      await db.tripsDao.replaceGpsPoints(tViaje, []);

      expect(await db.tripsDao.getGpsPoints(tViaje), isEmpty);
    });

    test('replaceIncidencias borra las que ya no vienen', () async {
      await db.tripsDao.replaceIncidencias(tViaje, [incidencia('viejo-1')]);

      await db.tripsDao.replaceIncidencias(tViaje, [incidencia('nuevo-1')]);

      final rows = await db.tripsDao.getIncidencias(tViaje);
      expect(rows.map((r) => r.id), ['nuevo-1']);
    });

    test('replaceAlertas borra las que ya no vienen', () async {
      await db.tripsDao.replaceAlertas(tViaje, [alerta('viejo-1')]);

      await db.tripsDao.replaceAlertas(tViaje, [alerta('nuevo-1')]);

      final rows = await db.tripsDao.getAlertas(tViaje);
      expect(rows.map((r) => r.id), ['nuevo-1']);
    });

    test('replaceReportesByViaje no toca los reportes sin viaje', () async {
      await db.tripsDao.replaceReportesByOperador(
        tOperador,
        [reporte('sin-viaje'), reporte('r-viaje', viajeId: tViaje)],
      );

      await db.tripsDao.replaceReportesByViaje(
        tViaje,
        [reporte('r-viaje-nuevo', viajeId: tViaje)],
      );

      expect(await reporteIds(), ['r-viaje-nuevo', 'sin-viaje']);
    });
  });

  group('TripsDao.replaceReportesByOperador —', () {
    test('borra los reportes que ya no vienen del servidor', () async {
      await db.tripsDao.replaceReportesByOperador(
        tOperador,
        [reporte('viejo-1'), reporte('viejo-2')],
      );

      await db.tripsDao
          .replaceReportesByOperador(tOperador, [reporte('nuevo-1')]);

      expect(await reporteIds(), ['nuevo-1']);
    });

    test('actualiza los reportes que siguen viniendo', () async {
      await db.tripsDao.replaceReportesByOperador(
        tOperador,
        [reporte('r1', descripcion: 'Antes')],
      );

      await db.tripsDao.replaceReportesByOperador(
        tOperador,
        [reporte('r1', descripcion: 'Después')],
      );

      final rows = await db.select(db.reportesTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.descripcion, 'Después');
    });

    test('barre también los reportes ligados a un viaje', () async {
      // Los escribe `replaceReportesByViaje`; al pertenecer al operador,
      // vuelven en la consulta por operador y el barrido los cubre.
      await db.tripsDao.replaceReportesByViaje(
        tViaje,
        [reporte('r-viaje', viajeId: tViaje)],
      );

      await db.tripsDao.replaceReportesByOperador(tOperador, [reporte('r1')]);

      expect(await reporteIds(), ['r1']);
    });

    test('no toca los reportes de otro operador', () async {
      await db.tripsDao.replaceReportesByOperador(
        tOtroOperador,
        [reporte('otro-1', operadorId: tOtroOperador)],
      );

      await db.tripsDao.replaceReportesByOperador(tOperador, [reporte('r1')]);

      expect(await reporteIds(), unorderedEquals(['r1', 'otro-1']));
    });

    test('con lista vacía borra solo lo del operador', () async {
      await db.tripsDao.replaceReportesByOperador(tOperador, [reporte('r1')]);
      await db.tripsDao.replaceReportesByOperador(
        tOtroOperador,
        [reporte('otro-1', operadorId: tOtroOperador)],
      );

      await db.tripsDao.replaceReportesByOperador(tOperador, []);

      expect(await reporteIds(), ['otro-1']);
    });
  });
}
