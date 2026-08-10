import 'package:drift/drift.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/tables.dart';

part 'points_dao.g.dart';

@DriftAccessor(tables: [MovimientosPuntosTable])
class PointsDao extends DatabaseAccessor<AppDatabase> with _$PointsDaoMixin {
  PointsDao(AppDatabase db) : super(db);

  // ─── Queries ──────────────────────────────────────────────────────────────

  Stream<List<MovimientoRow>> watchByOperador(String operadorId) =>
      (select(movimientosPuntosTable)
            ..where((t) => t.operadorId.equals(operadorId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> upsertAll(
    List<MovimientosPuntosTableCompanion> rows,
  ) =>
      batch(
        (b) => b.insertAllOnConflictUpdate(movimientosPuntosTable, rows),
      );

  /// Deja los movimientos locales del operador iguales a los del servidor.
  ///
  /// Mismo motivo que `RewardsDao.replaceCatalogo`: tras un `supabase db reset`
  /// los `id` se regeneran y el historial de puntos quedaba mostrando los
  /// movimientos de cada base anterior encimados con los nuevos.
  Future<void> replaceMovimientos(
    String operadorId,
    List<MovimientosPuntosTableCompanion> rows,
  ) =>
      transaction(() async {
        final ids = rows.map((r) => r.id.value).toList();
        final stale = delete(movimientosPuntosTable)
          ..where((t) => t.operadorId.equals(operadorId));
        // `NOT IN ()` no es SQL válido: sin filas, se borra todo lo suyo.
        if (ids.isNotEmpty) {
          stale.where((t) => t.id.isNotIn(ids));
        }
        await stale.go();
        if (rows.isEmpty) return;
        await batch(
          (b) => b.insertAllOnConflictUpdate(movimientosPuntosTable, rows),
        );
      });
}
