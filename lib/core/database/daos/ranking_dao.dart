import 'package:drift/drift.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/tables.dart';

part 'ranking_dao.g.dart';

@DriftAccessor(tables: [RankingTable])
class RankingDao extends DatabaseAccessor<AppDatabase> with _$RankingDaoMixin {
  RankingDao(AppDatabase db) : super(db);

  Stream<List<RankingRow>> watchByPeriodo(String periodo) {
    final query = select(rankingTable)
      ..where((t) => t.periodo.equals(periodo))
      ..orderBy([(t) => OrderingTerm.asc(t.posicion)]);
    return query.watch();
  }

  Future<RankingRow?> getByOperador(String periodo, String operadorId) {
    final query = select(rankingTable)
      ..where(
        (t) => t.periodo.equals(periodo) & t.operadorId.equals(operadorId),
      );
    return query.getSingleOrNull();
  }

  // Reemplazo completo: las posiciones se recorren y algunos operadores
  // salen del ranking, así que un upsert parcial dejaría filas obsoletas.
  Future<void> replacePeriodo(
    String periodo,
    List<RankingTableCompanion> rows,
  ) =>
      transaction(() async {
        await (delete(rankingTable)..where((t) => t.periodo.equals(periodo)))
            .go();
        await batch((b) => b.insertAll(rankingTable, rows));
      });

  Future<DateTime?> getLastUpdatedAt(String periodo) async {
    final query = select(rankingTable)
      ..where((t) => t.periodo.equals(periodo))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.updatedAt;
  }
}
