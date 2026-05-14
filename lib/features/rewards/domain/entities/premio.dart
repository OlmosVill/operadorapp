import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';

part 'premio.freezed.dart';

enum PremioTipo { tarjetaRegalo, producto, experiencia, vehiculo, otro }

extension PremioTipoX on PremioTipo {
  String get displayName => switch (this) {
        PremioTipo.tarjetaRegalo => 'Tarjeta Regalo',
        PremioTipo.producto => 'Producto',
        PremioTipo.experiencia => 'Experiencia',
        PremioTipo.vehiculo => 'Vehículo',
        PremioTipo.otro => 'Otro',
      };

  static PremioTipo fromString(String value) => switch (value) {
        'tarjeta_regalo' => PremioTipo.tarjetaRegalo,
        'experiencia' => PremioTipo.experiencia,
        'vehiculo' => PremioTipo.vehiculo,
        'producto' => PremioTipo.producto,
        _ => PremioTipo.otro,
      };
}

enum CanjeEstado { solicitado, aprobado, rechazado, entregado }

extension CanjeEstadoX on CanjeEstado {
  String get displayName => switch (this) {
        CanjeEstado.solicitado => 'Solicitado',
        CanjeEstado.aprobado => 'Aprobado',
        CanjeEstado.rechazado => 'Rechazado',
        CanjeEstado.entregado => 'Entregado',
      };

  static CanjeEstado fromString(String value) => switch (value) {
        'aprobado' => CanjeEstado.aprobado,
        'rechazado' => CanjeEstado.rechazado,
        'entregado' => CanjeEstado.entregado,
        _ => CanjeEstado.solicitado,
      };
}

@freezed
sealed class Premio with _$Premio {
  const factory Premio({
    required String id,
    required String nombre,
    required PremioTipo tipo,
    required int costoPuntos,
    required bool activo,
    String? descripcion,
    OperatorLevel? nivelMinimo,
    String? imagenUrl,
    int? stock,
    int? orden,
  }) = _Premio;
}

@freezed
sealed class Canje with _$Canje {
  const factory Canje({
    required String id,
    required String operadorId,
    required String premioId,
    required int puntosCanjeados,
    required CanjeEstado estado,
    required DateTime fechaSolicitud,
    required DateTime updatedAt,
  }) = _Canje;
}
