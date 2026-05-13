import 'package:drift/drift.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/tables.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncMetadataTable])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(AppDatabase db) : super(db);

  Future<DateTime?> getLastSyncAt(String table) async {
    final row = await (select(syncMetadataTable)
          ..where((t) => t.tableKey.equals(table)))
        .getSingleOrNull();
    return row?.lastSyncAt;
  }

  Future<void> setLastSyncAt(String table, DateTime syncAt) =>
      into(syncMetadataTable).insertOnConflictUpdate(
        SyncMetadataTableCompanion.insert(
          tableKey: table,
          lastSyncAt: Value(syncAt),
        ),
      );
}
