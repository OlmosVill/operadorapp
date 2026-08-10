import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/core/database/app_database.dart';

/// El catálogo local se quedaba con premios de bases anteriores.
///
/// `supabase db reset` regenera los `id` del catálogo, y como el sync solo
/// insertaba, la app terminaba mostrando cada premio dos veces y mandando a
/// canjear un `id` que el servidor ya no conoce.
void main() {
  late AppDatabase db;

  PremiosCatalogoTableCompanion premio(String id, String nombre) =>
      PremiosCatalogoTableCompanion(
        id: Value(id),
        nombre: Value(nombre),
        tipo: const Value('tarjeta_regalo'),
        costoPuntos: const Value(500),
        activo: const Value(true),
        updatedAt: Value(DateTime.utc(2026, 8)),
      );

  PremiosCanjeadosTableCompanion canje(String id, String operadorId) =>
      PremiosCanjeadosTableCompanion(
        id: Value(id),
        operadorId: Value(operadorId),
        premioId: const Value('premio-nuevo'),
        puntosCanjeados: const Value(500),
        estado: const Value('solicitado'),
        fechaSolicitud: Value(DateTime.utc(2026, 8)),
        updatedAt: Value(DateTime.utc(2026, 8)),
      );

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('RewardsDao.replaceCatalogo —', () {
    test('borra los premios que ya no están en el servidor', () async {
      await db.rewardsDao.upsertPremios([
        premio('viejo', r'Tarjeta de regalo $500'),
        premio('nuevo', r'Tarjeta de regalo $500'),
      ]);

      await db.rewardsDao.replaceCatalogo([
        premio('nuevo', r'Tarjeta de regalo $500'),
      ]);

      final rows = await db.rewardsDao.watchCatalogo().first;
      expect(rows.map((r) => r.id), ['nuevo']);
    });

    test('con catálogo vacío deja la tabla vacía', () async {
      await db.rewardsDao.upsertPremios([premio('viejo', 'Lo que sea')]);

      await db.rewardsDao.replaceCatalogo([]);

      expect(await db.rewardsDao.watchCatalogo().first, isEmpty);
    });

    test('actualiza los premios que siguen existiendo', () async {
      await db.rewardsDao.upsertPremios([premio('nuevo', 'Nombre viejo')]);

      await db.rewardsDao.replaceCatalogo([premio('nuevo', 'Nombre nuevo')]);

      final rows = await db.rewardsDao.watchCatalogo().first;
      expect(rows.single.nombre, 'Nombre nuevo');
    });
  });

  group('RewardsDao.replaceCanjes —', () {
    test('borra los canjes huérfanos del operador', () async {
      await db.rewardsDao.upsertCanjes([
        canje('viejo', 'op-1'),
        canje('nuevo', 'op-1'),
      ]);

      await db.rewardsDao.replaceCanjes('op-1', [canje('nuevo', 'op-1')]);

      final rows = await db.rewardsDao.watchByOperador('op-1').first;
      expect(rows.map((r) => r.id), ['nuevo']);
    });

    test('no toca los canjes de otro operador', () async {
      await db.rewardsDao.upsertCanjes([
        canje('ajeno', 'op-2'),
        canje('propio', 'op-1'),
      ]);

      await db.rewardsDao.replaceCanjes('op-1', []);

      expect(await db.rewardsDao.watchByOperador('op-1').first, isEmpty);
      expect(await db.rewardsDao.watchByOperador('op-2').first, hasLength(1));
    });

    // El caso con lista no vacía recorre la rama de los dos `where`
    // encadenados (operador + `isNotIn`), que la lista vacía se salta.
    test('con lista no vacía tampoco cruza operadores', () async {
      await db.rewardsDao.upsertCanjes([canje('ajeno', 'op-2')]);

      await db.rewardsDao.replaceCanjes('op-1', [canje('propio', 'op-1')]);

      expect(await db.rewardsDao.watchByOperador('op-2').first, hasLength(1));
    });
  });
}
