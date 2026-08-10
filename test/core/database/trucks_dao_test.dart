import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  const tOperador = 'operador-uuid-001';
  const tOtroOperador = 'operador-uuid-002';
  final tFecha = DateTime.utc(2026, 8);

  TractosTableCompanion tracto(String id, {String economico = 'T-100'}) =>
      TractosTableCompanion(
        id: Value(id),
        numeroEconomico: Value(economico),
        updatedAt: Value(tFecha),
      );

  HistorialTractosTableCompanion historial(
    String id, {
    String operadorId = tOperador,
    String tractoId = 'tracto-001',
  }) =>
      HistorialTractosTableCompanion(
        id: Value(id),
        operadorId: Value(operadorId),
        tractoId: Value(tractoId),
        fechaInicio: Value(tFecha),
        updatedAt: Value(tFecha),
      );

  Future<List<String>> tractoIds() async {
    final rows = await db.select(db.tractosTable).get();
    return rows.map((r) => r.id).toList()..sort();
  }

  Future<List<String>> historialIds() async {
    final rows = await db.select(db.historialTractosTable).get();
    return rows.map((r) => r.id).toList()..sort();
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TrucksDao.replaceTractos —', () {
    test('borra los tractos que ya no vienen del servidor', () async {
      await db.trucksDao.replaceTractos([tracto('viejo-1'), tracto('viejo-2')]);

      await db.trucksDao.replaceTractos([tracto('nuevo-1')]);

      expect(await tractoIds(), ['nuevo-1']);
    });

    test('actualiza los tractos que siguen viniendo', () async {
      await db.trucksDao.replaceTractos([tracto('t1')]);

      await db.trucksDao.replaceTractos([tracto('t1', economico: 'T-200')]);

      final rows = await db.select(db.tractosTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.numeroEconomico, 'T-200');
    });

    test('con lista vacía vacía la tabla local', () async {
      await db.trucksDao.replaceTractos([tracto('t1')]);

      await db.trucksDao.replaceTractos([]);

      expect(await tractoIds(), isEmpty);
    });
  });

  group('TrucksDao.replaceHistorial —', () {
    test('borra los registros del operador que ya no existen', () async {
      await db.trucksDao.replaceHistorial(
        tOperador,
        [historial('h1'), historial('h2')],
      );

      await db.trucksDao.replaceHistorial(tOperador, [historial('h2')]);

      expect(await historialIds(), ['h2']);
    });

    test('no toca el historial de otro operador', () async {
      await db.trucksDao.replaceHistorial(
        tOtroOperador,
        [historial('otro-1', operadorId: tOtroOperador)],
      );

      await db.trucksDao.replaceHistorial(tOperador, [historial('h1')]);

      expect(await historialIds(), ['h1', 'otro-1']);
    });

    test('con lista vacía borra solo lo del operador', () async {
      await db.trucksDao.replaceHistorial(tOperador, [historial('h1')]);
      await db.trucksDao.replaceHistorial(
        tOtroOperador,
        [historial('otro-1', operadorId: tOtroOperador)],
      );

      await db.trucksDao.replaceHistorial(tOperador, []);

      expect(await historialIds(), ['otro-1']);
    });
  });
}
