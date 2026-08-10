import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/trips/domain/entities/gps_point.dart';
import 'package:operadorapp/features/trips/domain/entities/security_alert.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_detail.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trips/presentation/providers/truck_scene_provider.dart';
import 'package:operadorapp/features/trips/presentation/screens/modernist/active_trip_home_screen.dart';

import 'modernist_golden_harness.dart';

/// Compara «Inicio Viaje Activo» contra su export, en los dos temas.
///
/// ```sh
/// flutter test --update-goldens test/features/trips/modernist
/// ```
///
/// Este es el patrón a repetir con cada pantalla que se migre; el montaje
/// común vive en `modernist_golden_harness.dart`.
void main() {
  const tripId = 'a1b2c3d4-0000-4000-8000-000000001842';

  final trip = Trip(
    id: tripId,
    operadorId: 'op-1',
    origen: 'Monterrey, NL',
    destino: 'Guadalajara, JAL',
    estado: TripStatus.enCurso,
    createdAt: DateTime(2026, 8, 5, 6),
    updatedAt: DateTime(2026, 8, 5, 12),
    fechaInicio: DateTime(2026, 8, 5, 6),
    kmEsperados: 703,
    kmRecorridos: 486,
    rendimientoReal: 4.6,
  );

  final profile = OperatorProfile(
    id: 'op-1',
    employeeNumber: '12345',
    fullName: 'Juan Ramírez Solís',
    startDate: DateTime(2022, 1, 15),
    level: OperatorLevel.oro,
    totalPoints: 5589,
    availablePoints: 3200,
  );

  final detail = TripDetail(
    trip: trip,
    securityAlerts: [
      SecurityAlert(
        id: 'alert-1',
        viajeId: tripId,
        tipo: 'frenado_brusco',
        timestampAlerta: DateTime(2026, 8, 5, 9, 30),
      ),
    ],
    gpsPoints: [
      GpsPoint(
        id: 'gps-1',
        viajeId: tripId,
        lat: 25.68,
        lng: -100.31,
        timestampGps: DateTime(2026, 8, 5, 12),
        velocidadKmh: 76,
      ),
    ],
  );

  // Cada export fija su propia hora por omisión, y de ahí sale la escena: el
  // claro arranca a las 15:00 (día) y el oscuro a las 21:00 (noche). La escena
  // del tracto no depende del tema — solo de la hora.
  // Cada export fija su propia hora por omisión, y de ahí sale la escena.
  final variants = <(String, Brightness, double)>[
    ('claro', Brightness.light, 15),
    ('oscuro', Brightness.dark, 21),
  ];

  for (final (name, brightness, hour) in variants) {
    testWidgets('Home con viaje activo coincide con el export $name',
        (tester) async {
      await setUpModernistGolden(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripDetailProvider(tripId).overrideWith((ref) async => detail),
            // Sin fijar la hora el golden cambiaría según cuándo se corra.
            sceneTimeOfDayProvider.overrideWithValue(hour),
          ],
          child: MaterialApp(
            // `ModernistPalette.of` resuelve por el brillo del tema activo.
            theme: ThemeData(brightness: brightness),
            home: ActiveTripHomeScreen(profile: profile, trip: trip),
          ),
        ),
      );

      // El detalle resuelve en un microtask; luego se deja correr medio segundo
      // para que la barra de progreso y el parallax salgan del estado inicial.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(ActiveTripHomeScreen),
        matchesGoldenFile('goldens/active_trip_home_$name.png'),
      );
    });
  }
}
