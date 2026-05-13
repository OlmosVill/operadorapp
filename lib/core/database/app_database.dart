import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:operadorapp/core/database/daos/profile_dao.dart';
import 'package:operadorapp/core/database/daos/sync_dao.dart';
import 'package:operadorapp/core/database/daos/trips_dao.dart';
import 'package:operadorapp/core/database/tables.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    OperadoresTable,
    ViajesTable,
    GpsPuntosTable,
    IncidenciasTable,
    AlertasTable,
    ReportesTable,
    PremiosCatalogoTable,
    PremiosCanjeadosTable,
    MovimientosPuntosTable,
    NotificacionesTable,
    PendingOpsTable,
    SyncMetadataTable,
  ],
  daos: [
    ProfileDao,
    TripsDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'operadorapp.db'));
      return NativeDatabase.createInBackground(file);
    });
