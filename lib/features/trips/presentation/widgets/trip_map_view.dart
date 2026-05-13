import 'package:flutter/material.dart';
import 'package:operadorapp/core/config/app_config.dart';
import 'package:operadorapp/core/maps/google_map_adapter.dart';
import 'package:operadorapp/core/maps/osm_map_adapter.dart';
import 'package:operadorapp/features/trips/domain/entities/gps_point.dart';

class TripMapView extends StatelessWidget {
  const TripMapView({
    required this.points,
    this.height = 240,
    super.key,
  });

  final List<GpsPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    final adapter = AppConfig.instance.mapProvider == MapProvider.google
        ? const GoogleMapAdapter()
        : const OsmMapAdapter();
    return adapter.buildMap(points: points, height: height);
  }
}
