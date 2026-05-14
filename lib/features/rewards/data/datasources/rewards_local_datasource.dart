import 'package:drift/drift.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';

class RewardsLocalDatasource {
  const RewardsLocalDatasource(this._db);

  final AppDatabase _db;

  Stream<List<Premio>> watchCatalogo() => _db.rewardsDao.watchCatalogo().map(
        (rows) => rows.map(_premioFromRow).toList(),
      );

  Stream<List<Canje>> watchCanjes(String operadorId) =>
      _db.rewardsDao.watchByOperador(operadorId).map(
            (rows) => rows.map(_canjeFromRow).toList(),
          );

  Future<void> upsertCanje(Canje canje) => _db.rewardsDao.upsertCanjes([
        PremiosCanjeadosTableCompanion(
          id: Value(canje.id),
          operadorId: Value(canje.operadorId),
          premioId: Value(canje.premioId),
          puntosCanjeados: Value(canje.puntosCanjeados),
          estado: Value(canje.estado.name),
          fechaSolicitud: Value(canje.fechaSolicitud),
          updatedAt: Value(canje.updatedAt),
        ),
      ]);

  static Premio _premioFromRow(PremioRow r) => Premio(
        id: r.id,
        nombre: r.nombre,
        descripcion: r.descripcion,
        tipo: PremioTipoX.fromString(r.tipo),
        costoPuntos: r.costoPuntos,
        nivelMinimo: r.nivelMinimo != null
            ? OperatorLevelX.fromString(r.nivelMinimo!)
            : null,
        imagenUrl: r.imagenUrl,
        stock: r.stock,
        activo: r.activo,
        orden: r.orden,
      );

  static Canje _canjeFromRow(CanjeRow r) => Canje(
        id: r.id,
        operadorId: r.operadorId,
        premioId: r.premioId,
        puntosCanjeados: r.puntosCanjeados,
        estado: CanjeEstadoX.fromString(r.estado),
        fechaSolicitud: r.fechaSolicitud,
        updatedAt: r.updatedAt,
      );
}
