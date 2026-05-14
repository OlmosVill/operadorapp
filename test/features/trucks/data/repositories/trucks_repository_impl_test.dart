import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/daos/trucks_dao.dart';
import 'package:operadorapp/features/trucks/data/repositories/trucks_repository_impl.dart';
import 'package:operadorapp/features/trucks/domain/entities/truck.dart';

// ─── Fake DAO ────────────────────────────────────────────────────────────────

class _FakeTrucksDao extends Fake implements TrucksDao {
  List<(HistorialTractoRow, TractoRow?)> pairs = [];
  List<ReporteRow> reportes = [];
  List<ViajeRow> viajes = [];

  @override
  Stream<List<(HistorialTractoRow, TractoRow?)>> watchByOperador(
    String operadorId,
  ) =>
      Stream.value(pairs);

  @override
  Future<List<ReporteRow>> getReportesByTracto(String tractoId) async =>
      reportes;

  @override
  Future<List<ViajeRow>> getViajesByTracto(
    String tractoId,
    String operadorId,
  ) async =>
      viajes;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

final _now = DateTime.now();

HistorialTractoRow _historial({
  String id = 'h1',
  String operadorId = 'op1',
  String tractoId = 't1',
  double kmRecorridos = 5000,
  int viajesRealizados = 10,
  double? calificacionPromedio = 8.5,
  bool esActual = false,
}) =>
    HistorialTractoRow(
      id: id,
      operadorId: operadorId,
      tractoId: tractoId,
      fechaInicio: _now,
      kmRecorridos: kmRecorridos,
      viajesRealizados: viajesRealizados,
      calificacionPromedio: calificacionPromedio,
      esActual: esActual,
      updatedAt: _now,
    );

TractoRow _tracto({
  String id = 't1',
  String numeroEconomico = 'T-001',
  String? marca = 'Kenworth',
  String? modelo = 'T800',
  int? anio = 2020,
  String? placa = 'ABC123',
  double? rendimientoEsperado = 4.5,
}) =>
    TractoRow(
      id: id,
      numeroEconomico: numeroEconomico,
      marca: marca,
      modelo: modelo,
      anio: anio,
      placa: placa,
      rendimientoEsperado: rendimientoEsperado,
      activo: true,
      updatedAt: _now,
    );

ReporteRow _reporte({
  String id = 'r1',
  String tipo = 'mantenimiento',
  String estado = 'abierto',
}) =>
    ReporteRow(
      id: id,
      operadorId: 'op1',
      tractoId: 't1',
      tipo: tipo,
      estado: estado,
      descripcion: 'Descripción de prueba',
      fotosUrls: '[]',
      fechaReporte: _now,
      updatedAt: _now,
    );

ViajeRow _viaje({double? rendimientoReal}) => ViajeRow(
      id: 'v1',
      operadorId: 'op1',
      tractoId: 't1',
      origen: 'Ciudad A',
      destino: 'Ciudad B',
      rendimientoReal: rendimientoReal,
      estado: 'completado',
      puntosObtenidos: 0,
      createdAt: _now,
      updatedAt: _now,
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late _FakeTrucksDao dao;
  late TrucksRepositoryImpl repo;

  setUp(() {
    dao = _FakeTrucksDao();
    repo = TrucksRepositoryImpl(dao);
  });

  group('TrucksRepositoryImpl.watchByOperador', () {
    test('emite lista vacía cuando no hay historial', () async {
      dao.pairs = [];

      final stream = repo.watchByOperador('op1');
      final result = await stream.first;

      expect(
        result,
        isA<Right<dynamic, List<TruckSummary>>>()
            .having((r) => r.value, 'value', isEmpty),
      );
    });

    test('mapea par (historial, tracto) a TruckSummary correctamente',
        () async {
      dao.pairs = [(_historial(esActual: true), _tracto())];

      final stream = repo.watchByOperador('op1');
      final result = await stream.first;

      final summaries = (result as Right<dynamic, List<TruckSummary>>).value;
      expect(summaries, hasLength(1));
      expect(summaries.first.numeroEconomico, 'T-001');
      expect(summaries.first.marca, 'Kenworth');
      expect(summaries.first.kmRecorridos, 5000);
      expect(summaries.first.viajesRealizados, 10);
      expect(summaries.first.esActual, isTrue);
    });

    test('usa tractoId como numeroEconomico cuando no hay datos del tracto',
        () async {
      dao.pairs = [(_historial(tractoId: 't-sin-datos'), null)];

      final stream = repo.watchByOperador('op1');
      final result = await stream.first;

      final summaries = (result as Right<dynamic, List<TruckSummary>>).value;
      expect(summaries.first.numeroEconomico, 't-sin-datos');
    });
  });

  group('TrucksRepositoryImpl.getReportes', () {
    test('retorna lista de reportes mapeados', () async {
      dao.reportes = [
        _reporte(),
        _reporte(id: 'r2', tipo: 'choque', estado: 'cerrado'),
      ];

      final result = await repo.getReportes('t1');

      final reports = (result as Right<dynamic, List<TruckReport>>).value;
      expect(reports, hasLength(2));
      expect(reports.first.tipo, 'mantenimiento');
      expect(reports.last.estado, 'cerrado');
    });

    test('retorna lista vacía si no hay reportes', () async {
      dao.reportes = [];

      final result = await repo.getReportes('t1');

      expect(
        result,
        isA<Right<dynamic, List<TruckReport>>>()
            .having((r) => r.value, 'value', isEmpty),
      );
    });
  });

  group('TrucksRepositoryImpl.getRendimientoPromedio', () {
    test('calcula promedio de rendimiento de viajes', () async {
      dao.viajes = [
        _viaje(rendimientoReal: 4),
        _viaje(rendimientoReal: 5),
      ];

      final result = await repo.getRendimientoPromedio('t1', 'op1');

      expect(
        (result as Right<dynamic, double?>).value,
        closeTo(4.5, 0.001),
      );
    });

    test('retorna null si ningún viaje tiene rendimiento registrado', () async {
      dao.viajes = [_viaje(), _viaje()];

      final result = await repo.getRendimientoPromedio('t1', 'op1');

      expect((result as Right<dynamic, double?>).value, isNull);
    });

    test('retorna null si no hay viajes', () async {
      dao.viajes = [];

      final result = await repo.getRendimientoPromedio('t1', 'op1');

      expect((result as Right<dynamic, double?>).value, isNull);
    });
  });
}
