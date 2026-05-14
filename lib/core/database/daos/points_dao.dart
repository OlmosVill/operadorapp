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

  Future<DateTime?> getLastCreatedAt(String operadorId) async {
    final query = select(movimientosPuntosTable)
      ..where((t) => t.operadorId.equals(operadorId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.createdAt;
  }

  Future<void> upsertAll(
    List<MovimientosPuntosTableCompanion> rows,
  ) =>
      batch(
        (b) => b.insertAllOnConflictUpdate(movimientosPuntosTable, rows),
      );
}
