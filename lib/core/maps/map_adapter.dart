import 'package:flutter/widgets.dart';
import 'package:operadorapp/features/trips/domain/entities/gps_point.dart';

abstract interface class MapAdapter {
  Widget buildMap({
    required List<GpsPoint> points,
    required double height,
  });
}
