import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';

abstract interface class ProfileLocalDatasource {
  Stream<OperatorProfile?> watchProfile(String authUserId);

  Future<OperatorProfile?> getProfile(String authUserId);
}

final class DriftProfileLocalDatasource implements ProfileLocalDatasource {
  const DriftProfileLocalDatasource(this._db);

  final AppDatabase _db;

  @override
  Stream<OperatorProfile?> watchProfile(String authUserId) =>
      _db.profileDao
          .watchByAuthUserId(authUserId)
          .map((row) => row == null ? null : _rowToProfile(row));

  @override
  Future<OperatorProfile?> getProfile(String authUserId) async {
    final row = await _db.profileDao.getByAuthUserId(authUserId);
    return row == null ? null : _rowToProfile(row);
  }

  OperatorProfile _rowToProfile(OperadorRow row) {
    final dateOnly = row.fechaIngreso.length > 10
        ? row.fechaIngreso.substring(0, 10)
        : row.fechaIngreso;

    return OperatorProfile(
      id: row.id,
      employeeNumber: row.numeroEmpleado,
      fullName: row.nombreCompleto,
      startDate: DateTime.parse(dateOnly),
      level: OperatorLevelX.fromString(row.nivelActual),
      totalPoints: row.puntosGanados,
      availablePoints: row.puntosDisponibles,
      email: row.email,
      phone: row.telefono,
      base: row.base,
      profilePhotoUrl: row.fotoPerfilUrl,
    );
  }
}
