import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:operadorapp/core/database/daos/points_dao.dart';
import 'package:operadorapp/core/database/daos/profile_dao.dart';
import 'package:operadorapp/core/database/daos/rewards_dao.dart';
import 'package:operadorapp/core/database/daos/sync_dao.dart';
import 'package:operadorapp/core/database/daos/trips_dao.dart';
import 'package:operadorapp/core/database/daos/trucks_dao.dart';
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
    TractosTable,
    HistorialTractosTable,
  ],
  daos: [
    PointsDao,
    ProfileDao,
    RewardsDao,
    SyncDao,
    TripsDao,
    TrucksDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(tractosTable);
            await m.createTable(historialTractosTable);
          }
        },
      );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'operadorapp.db'));
      return NativeDatabase.createInBackground(file);
    });
