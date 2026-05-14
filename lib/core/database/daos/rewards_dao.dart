import 'package:drift/drift.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/tables.dart';

part 'rewards_dao.g.dart';

@DriftAccessor(tables: [PremiosCatalogoTable, PremiosCanjeadosTable])
class RewardsDao
    extends DatabaseAccessor<AppDatabase>
    with _$RewardsDaoMixin {
  RewardsDao(AppDatabase db) : super(db);

  // ─── Catálogo ─────────────────────────────────────────────────────────────

  Stream<List<PremioRow>> watchCatalogo() =>
      (select(premiosCatalogoTable)
            ..where((t) => t.activo.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.orden)]))
          .watch();

  Future<DateTime?> getLastUpdatedAt() async {
    final query = select(premiosCatalogoTable)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.updatedAt;
  }

  Future<void> upsertPremios(
    List<PremiosCatalogoTableCompanion> rows,
  ) =>
      batch(
        (b) => b.insertAllOnConflictUpdate(premiosCatalogoTable, rows),
      );

  // ─── Canjes ───────────────────────────────────────────────────────────────

  Stream<List<CanjeRow>> watchByOperador(String operadorId) =>
      (select(premiosCanjeadosTable)
            ..where((t) => t.operadorId.equals(operadorId))
            ..orderBy(
              [(t) => OrderingTerm.desc(t.fechaSolicitud)],
            ))
          .watch();

  Future<void> upsertCanjes(
    List<PremiosCanjeadosTableCompanion> rows,
  ) =>
      batch(
        (b) => b.insertAllOnConflictUpdate(premiosCanjeadosTable, rows),
      );
}
