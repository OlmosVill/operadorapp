import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:operadorapp/features/trips/domain/entities/gps_point.dart';
import 'package:operadorapp/features/trips/domain/entities/security_alert.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_incident.dart';

part 'trip_detail.freezed.dart';

@freezed
sealed class TripDetail with _$TripDetail {
  const factory TripDetail({
    required Trip trip,
    @Default([]) List<TripIncident> incidents,
    @Default([]) List<SecurityAlert> securityAlerts,
    @Default([]) List<GpsPoint> gpsPoints,
  }) = _TripDetail;
}
