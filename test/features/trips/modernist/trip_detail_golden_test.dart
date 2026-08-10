import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/trips/domain/entities/gps_point.dart';
import 'package:operadorapp/features/trips/domain/entities/security_alert.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_detail.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_incident.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trips/presentation/screens/modernist/trip_detail_screen.dart';

import 'modernist_golden_harness.dart';

/// Compara «Detalle Viaje» contra su export, en los dos temas.
///
/// ```sh
/// flutter test --update-goldens test/features/trips/modernist
/// ```
void main() {
  // El viaje V-1829 del export: el que trae alertas e incidencias.
  const tripId = 'a1b2c3d4-0000-4000-8000-000000001829';
  final start = DateTime(2026, 7, 29, 5, 40);
  final end = DateTime(2026, 7, 29, 9, 12);

  final detail = TripDetail(
    trip: Trip(
      id: tripId,
      operadorId: 'op-1',
      origen: 'Monterrey, NL',
      destino: 'Nuevo Laredo, TAMPS',
      estado: TripStatus.completado,
      createdAt: start,
      updatedAt: end,
      fechaInicio: start,
      fechaFin: end,
      kmRecorridos: 224,
      rendimientoReal: 4.8,
      litrosDiesel: 46.7,
      calificacion: 4.5,
      puntosObtenidos: 148,
    ),
    incidents: [
      TripIncident(
        id: 'i1',
        viajeId: tripId,
        tipo: 'retraso_en_aduana',
        timestampIncidencia: DateTime(2026, 7, 29, 8, 5),
        descripcion: 'Fila de revisión en el cruce, 48 minutos detenido.',
        severidad: 4,
        impactoPuntos: -20,
      ),
      TripIncident(
        id: 'i2',
        viajeId: tripId,
        tipo: 'desvio_por_obra',
        timestampIncidencia: DateTime(2026, 7, 29, 6, 52),
        descripcion: 'Cierre parcial en la carretera federal 85.',
        severidad: 3,
        impactoPuntos: -20,
      ),
    ],
    securityAlerts: [
      SecurityAlert(
        id: 'a1',
        viajeId: tripId,
        tipo: 'exceso_de_velocidad',
        timestampAlerta: DateTime(2026, 7, 29, 7, 18),
        valorMedido: 104,
        umbralPermitido: 95,
        impactoPuntos: -5,
      ),
      SecurityAlert(
        id: 'a2',
        viajeId: tripId,
        tipo: 'frenado_brusco',
        timestampAlerta: DateTime(2026, 7, 29, 8, 41),
        valorMedido: 7.4,
        umbralPermitido: 5.5,
        impactoPuntos: -5,
      ),
    ],
    gpsPoints: [
      for (var i = 0; i < 1284; i++)
        GpsPoint(
          id: 'g$i',
          viajeId: tripId,
          lat: 25.68,
          lng: -100.31,
          timestampGps: start.add(Duration(seconds: i * 10)),
        ),
    ],
  );

  for (final (name, brightness) in modernistThemes) {
    testWidgets('Detalle de viaje coincide con el export $name',
        (tester) async {
      await setUpModernistGolden(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripDetailProvider(tripId).overrideWith((ref) async => detail),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const ModernistTripDetailScreen(tripId: tripId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(ModernistTripDetailScreen),
        matchesGoldenFile('goldens/trip_detail_$name.png'),
      );

      // El segundo tramo: incidencias y alertas quedan bajo el pliegue.
      await tester.drag(find.byType(ListView), const Offset(0, -420));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ModernistTripDetailScreen),
        matchesGoldenFile('goldens/trip_detail_${name}_eventos.png'),
      );
    });
  }
}
