import 'package:drift/drift.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/tables.dart';

part 'rewards_dao.g.dart';

@DriftAccessor(tables: [PremiosCatalogoTable, PremiosCanjeadosTable])
class RewardsDao extends DatabaseAccessor<AppDatabase> with _$RewardsDaoMixin {
  RewardsDao(AppDatabase db) : super(db);

  // ─── Catálogo ─────────────────────────────────────────────────────────────

  Stream<List<PremioRow>> watchCatalogo() => (select(premiosCatalogoTable)
        ..where((t) => t.activo.equals(true))
        ..orderBy([(t) => OrderingTerm.asc(t.orden)]))
      .watch();

  Future<void> upsertPremios(
    List<PremiosCatalogoTableCompanion> rows,
  ) =>
      batch(
        (b) => b.insertAllOnConflictUpdate(premiosCatalogoTable, rows),
      );

  /// Deja el catálogo local exactamente igual al del servidor.
  ///
  /// No basta con insertar: un premio que desaparece del servidor —o al que
  /// `supabase db reset` le cambia el `id`— se quedaría aquí para siempre, y
  /// canjearlo falla con «Premio no encontrado» porque ese `id` ya no existe
  /// allá. El catálogo es chico y lo manda el servidor, así que se reemplaza
  /// entero.
  Future<void> replaceCatalogo(
    List<PremiosCatalogoTableCompanion> rows,
  ) =>
      transaction(() async {
        final ids = rows.map((r) => r.id.value).toList();
        final stale = delete(premiosCatalogoTable);
        // `NOT IN ()` no es SQL válido: sin filas, se borra todo.
        if (ids.isNotEmpty) {
          stale.where((t) => t.id.isNotIn(ids));
        }
        await stale.go();
        if (rows.isEmpty) return;
        await batch(
          (b) => b.insertAllOnConflictUpdate(premiosCatalogoTable, rows),
        );
      });

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

  /// Deja los canjes locales del operador iguales a los del servidor.
  ///
  /// Mismo motivo que [replaceCatalogo]: el historial local acumulaba canjes
  /// de bases anteriores que ya no existen.
  Future<void> replaceCanjes(
    String operadorId,
    List<PremiosCanjeadosTableCompanion> rows,
  ) =>
      transaction(() async {
        final ids = rows.map((r) => r.id.value).toList();
        final stale = delete(premiosCanjeadosTable)
          ..where((t) => t.operadorId.equals(operadorId));
        if (ids.isNotEmpty) {
          stale.where((t) => t.id.isNotIn(ids));
        }
        await stale.go();
        if (rows.isEmpty) return;
        await batch(
          (b) => b.insertAllOnConflictUpdate(premiosCanjeadosTable, rows),
        );
      });
}
