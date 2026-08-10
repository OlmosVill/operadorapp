import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  const tAuthUser = 'auth-uuid-001';
  const tOtroAuthUser = 'auth-uuid-002';
  final tFecha = DateTime.utc(2026, 8);

  OperadoresTableCompanion operador(
    String id, {
    String authUserId = tAuthUser,
    String nombre = 'Juan Demo',
  }) =>
      OperadoresTableCompanion(
        id: Value(id),
        authUserId: Value(authUserId),
        numeroEmpleado: const Value('12345'),
        nombreCompleto: Value(nombre),
        fechaIngreso: const Value('2022-01-15'),
        updatedAt: Value(tFecha),
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('ProfileDao.replaceProfile —', () {
    test('borra el perfil de una base anterior', () async {
      // Tras un `supabase db reset` cambian tanto el id como el auth_user_id.
      await db.profileDao.replaceProfile(
        tOtroAuthUser,
        operador('viejo', authUserId: tOtroAuthUser),
      );

      await db.profileDao.replaceProfile(tAuthUser, operador('nuevo'));

      final rows = await db.select(db.operadoresTable).get();
      expect(rows.map((r) => r.id), ['nuevo']);
    });

    test('actualiza el perfil de la sesión activa', () async {
      await db.profileDao
          .replaceProfile(tAuthUser, operador('op-1', nombre: 'Antes'));

      await db.profileDao
          .replaceProfile(tAuthUser, operador('op-1', nombre: 'Después'));

      final row = await db.profileDao.getByAuthUserId(tAuthUser);
      expect(row?.nombreCompleto, 'Después');
    });
  });
}
