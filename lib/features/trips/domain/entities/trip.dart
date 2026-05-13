import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';

enum TripStatus { asignado, enCurso, completado, cancelado, incidente }

extension TripStatusX on TripStatus {
  String get displayName => switch (this) {
        TripStatus.asignado => 'Asignado',
        TripStatus.enCurso => 'En curso',
        TripStatus.completado => 'Completado',
        TripStatus.cancelado => 'Cancelado',
        TripStatus.incidente => 'Incidente',
      };

  static TripStatus fromString(String value) => switch (value) {
        'en_curso' => TripStatus.enCurso,
        'completado' => TripStatus.completado,
        'cancelado' => TripStatus.cancelado,
        'incidente' => TripStatus.incidente,
        _ => TripStatus.asignado,
      };
}

@freezed
sealed class Trip with _$Trip {
  const factory Trip({
    required String id,
    required String operadorId,
    required String origen,
    required String destino,
    required TripStatus estado,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? tractoId,
    double? origenLat,
    double? origenLng,
    double? destinoLat,
    double? destinoLng,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    double? kmEsperados,
    double? kmRecorridos,
    double? litrosDiesel,
    double? rendimientoReal,
    double? calificacion,
    @Default(0) int puntosObtenidos,
    String? notas,
  }) = _Trip;
}
