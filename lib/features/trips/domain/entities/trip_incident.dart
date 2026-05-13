import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_incident.freezed.dart';

@freezed
sealed class TripIncident with _$TripIncident {
  const factory TripIncident({
    required String id,
    required String viajeId,
    required String tipo,
    required DateTime timestampIncidencia,
    String? descripcion,
    int? severidad,
    double? lat,
    double? lng,
    @Default(0) int impactoPuntos,
  }) = _TripIncident;
}
