import 'package:freezed_annotation/freezed_annotation.dart';

part 'truck.freezed.dart';

@freezed
sealed class TruckSummary with _$TruckSummary {
  const factory TruckSummary({
    required String tractoId,
    required String historialId,
    required String numeroEconomico,
    required double kmRecorridos,
    required int viajesRealizados,
    required bool esActual,
    required DateTime fechaInicio,
    String? marca,
    String? modelo,
    int? anio,
    String? placa,
    double? rendimientoEsperado,
    double? calificacionPromedio,
    DateTime? fechaFin,
  }) = _TruckSummary;
}

@freezed
sealed class TruckReport with _$TruckReport {
  const factory TruckReport({
    required String id,
    required String tipo,
    required String estado,
    required String descripcion,
    required DateTime fechaReporte,
  }) = _TruckReport;
}
