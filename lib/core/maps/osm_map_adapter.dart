import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:operadorapp/core/maps/map_adapter.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/trips/domain/entities/gps_point.dart';

final class OsmMapAdapter implements MapAdapter {
  const OsmMapAdapter();

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

    final latLngs = points.map((p) => LatLng(p.lat, p.lng)).toList();
    final center = LatLng(
      latLngs.map((p) => p.latitude).reduce((a, b) => a + b) / latLngs.length,
      latLngs.map((p) => p.longitude).reduce((a, b) => a + b) / latLngs.length,
    );

    final mapOptions = latLngs.length >= 2
        ? MapOptions(
            initialCenter: center,
            initialCameraFit: CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(latLngs),
              padding: const EdgeInsets.all(32),
            ),
          )
        : MapOptions(
            initialCenter: center,
            initialZoom: 14,
          );

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: mapOptions,
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.operadorapp',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: latLngs,
                  color: AppColors.amber,
                  strokeWidth: 3,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: latLngs.first,
                  child: const Icon(
                    Icons.trip_origin,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                if (latLngs.length > 1)
                  Marker(
                    point: latLngs.last,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
