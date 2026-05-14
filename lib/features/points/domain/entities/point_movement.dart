import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_movement.freezed.dart';

enum MovementType {
  ganadoViaje,
  canjeado,
  ajusteManual,
  bonificacion,
  penalizacion,
}

extension MovementTypeX on MovementType {
  String get displayName => switch (this) {
        MovementType.ganadoViaje => 'Viaje completado',
        MovementType.canjeado => 'Canje de premio',
        MovementType.ajusteManual => 'Ajuste manual',
        MovementType.bonificacion => 'Bonificación',
        MovementType.penalizacion => 'Penalización',
      };

  bool get isCredit =>
      this == MovementType.ganadoViaje ||
      this == MovementType.bonificacion ||
      (this == MovementType.ajusteManual);

  static MovementType fromString(String value) => switch (value) {
        'ganado_viaje' => MovementType.ganadoViaje,
        'canjeado' => MovementType.canjeado,
        'ajuste_manual' => MovementType.ajusteManual,
        'bonificacion' => MovementType.bonificacion,
        'penalizacion' => MovementType.penalizacion,
        _ => MovementType.ajusteManual,
      };
}

@freezed
sealed class PointMovement with _$PointMovement {
  const factory PointMovement({
    required String id,
    required String operadorId,
    required MovementType tipo,
    required int puntos,
    required int saldoDespues,
    required DateTime createdAt,
    String? viajeId,
    String? canjeId,
    String? descripcion,
  }) = _PointMovement;
}
