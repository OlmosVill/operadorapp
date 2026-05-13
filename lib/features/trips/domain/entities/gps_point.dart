import 'package:freezed_annotation/freezed_annotation.dart';

part 'gps_point.freezed.dart';

@freezed
sealed class GpsPoint with _$GpsPoint {
  const factory GpsPoint({
    required String id,
    required String viajeId,
    required double lat,
    required double lng,
    required DateTime timestampGps,
    double? velocidadKmh,
    double? rumboGrados,
    double? altitudM,
  }) = _GpsPoint;
}
