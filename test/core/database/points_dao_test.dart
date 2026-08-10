import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  const tOperador = 'operador-uuid-001';
  const tOtroOperador = 'operador-uuid-002';
  final tFecha = DateTime.utc(2026, 8);

  MovimientosPuntosTableCompanion movimiento(
    String id, {
    String operadorId = tOperador,
    int puntos = 100,
  }) =>
      MovimientosPuntosTableCompanion(
        id: Value(id),
        operadorId: Value(operadorId),
        tipo: const Value('viaje_completado'),
        puntos: Value(puntos),
        saldoDespues: Value(puntos),
        createdAt: Value(tFecha),
      );

  Future<List<String>> movimientoIds() async {
    final rows = await db.select(db.movimientosPuntosTable).get();
    return rows.map((r) => r.id).toList()..sort();
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('PointsDao.replaceMovimientos —', () {
    test('borra los movimientos que ya no vienen del servidor', () async {
      // Simula los ids regenerados por un `supabase db reset`.
      await db.pointsDao.replaceMovimientos(
        tOperador,
        [movimiento('viejo-1'), movimiento('viejo-2')],
      );

      await db.pointsDao.replaceMovimientos(tOperador, [movimiento('nuevo-1')]);

      expect(await movimientoIds(), ['nuevo-1']);
    });

    test('actualiza los movimientos que siguen viniendo', () async {
      await db.pointsDao.replaceMovimientos(tOperador, [movimiento('m1')]);

      await db.pointsDao
          .replaceMovimientos(tOperador, [movimiento('m1', puntos: 250)]);

      final rows = await db.select(db.movimientosPuntosTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.puntos, 250);
    });

    test('no toca los movimientos de otro operador', () async {
      await db.pointsDao.replaceMovimientos(
        tOtroOperador,
        [movimiento('otro-1', operadorId: tOtroOperador)],
      );

      await db.pointsDao.replaceMovimientos(tOperador, [movimiento('m1')]);

      expect(await movimientoIds(), ['m1', 'otro-1']);
    });

    test('con lista vacía borra solo lo del operador', () async {
      await db.pointsDao.replaceMovimientos(tOperador, [movimiento('m1')]);
      await db.pointsDao.replaceMovimientos(
        tOtroOperador,
        [movimiento('otro-1', operadorId: tOtroOperador)],
      );

      await db.pointsDao.replaceMovimientos(tOperador, []);

      expect(await movimientoIds(), ['otro-1']);
    });
  });
}
