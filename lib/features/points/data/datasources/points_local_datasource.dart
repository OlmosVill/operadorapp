import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';

class PointsLocalDatasource {
  const PointsLocalDatasource(this._db);

  final AppDatabase _db;

  Stream<List<PointMovement>> watchMovimientos(String operadorId) =>
      _db.pointsDao
          .watchByOperador(operadorId)
          .map((rows) => rows.map(_toEntity).toList());

  static PointMovement _toEntity(MovimientoRow row) => PointMovement(
        id: row.id,
        operadorId: row.operadorId,
        tipo: MovementTypeX.fromString(row.tipo),
        puntos: row.puntos,
        saldoDespues: row.saldoDespues,
        createdAt: row.createdAt,
        viajeId: row.viajeId,
        canjeId: row.canjeId,
        descripcion: row.descripcion,
      );
}
