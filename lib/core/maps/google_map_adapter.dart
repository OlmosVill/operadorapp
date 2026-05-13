import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:operadorapp/core/maps/map_adapter.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/trips/domain/entities/gps_point.dart';

final class GoogleMapAdapter implements MapAdapter {
  const GoogleMapAdapter();

  @override
  Widget buildMap({
    required List<GpsPoint> points,
    required double height,
  }) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Sin datos GPS para este viaje'),
        ),
      );
    }

    final gPoints =
        points.map((p) => gmaps.LatLng(p.lat, p.lng)).toList();
    final center = gmaps.LatLng(
      points.map((p) => p.lat).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.lng).reduce((a, b) => a + b) / points.length,
    );

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: center,
            zoom: 12,
          ),
          polylines: {
            gmaps.Polyline(
              polylineId: const gmaps.PolylineId('route'),
              points: gPoints,
              color: AppColors.amber,
              width: 3,
            ),
          },
          markers: {
            gmaps.Marker(
              markerId: const gmaps.MarkerId('start'),
              position: gPoints.first,
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                gmaps.BitmapDescriptor.hueGreen,
              ),
            ),
            gmaps.Marker(
              markerId: const gmaps.MarkerId('end'),
              position: gPoints.last,
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}
