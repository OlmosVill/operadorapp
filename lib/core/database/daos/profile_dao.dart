import 'package:drift/drift.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/database/tables.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [OperadoresTable])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(AppDatabase db) : super(db);

  Future<OperadorRow?> getByAuthUserId(String authUserId) =>
      (select(operadoresTable)..where((t) => t.authUserId.equals(authUserId)))
          .getSingleOrNull();

  Stream<OperadorRow?> watchByAuthUserId(String authUserId) =>
      (select(operadoresTable)..where((t) => t.authUserId.equals(authUserId)))
          .watchSingleOrNull();

  Future<void> upsert(OperadoresTableCompanion data) =>
      into(operadoresTable).insertOnConflictUpdate(data);
}
