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

  /// Deja en la tabla local sólo el perfil de la sesión activa.
  ///
  /// Cada `supabase db reset` regenera el `auth_user_id`, así que sin el
  /// barrido se va juntando una fila muerta por cada base anterior. No se
  /// notaba porque las lecturas filtran por `auth_user_id`.
  Future<void> replaceProfile(
    String authUserId,
    OperadoresTableCompanion data,
  ) =>
      transaction(() async {
        await (delete(operadoresTable)
              ..where((t) => t.authUserId.equals(authUserId).not()))
            .go();
        await into(operadoresTable).insertOnConflictUpdate(data);
      });
}
