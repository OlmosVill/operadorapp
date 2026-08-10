import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/home_provider.dart';
import 'package:operadorapp/features/trips/presentation/screens/modernist/idle_home_screen.dart';

import 'modernist_golden_harness.dart';

/// Compara «Inicio Sin Viaje» contra su export, en los dos temas y en las dos
/// secciones que se recorren con snap vertical.
///
/// ```sh
/// flutter test --update-goldens test/features/trips/modernist
/// ```
///
/// El rótulo «Almacén · Andén 3» pide la monoespaciada del sistema; ver
/// `setUpModernistGolden` para cómo se resuelve en el arnés.
void main() {
  // El dataset del export: 4 viajes cerrados en días consecutivos, 628 km y
  // 711 puntos en el mes, racha de 4.
  final trips = [
    _trip('t1', 'Reynosa', 'Monterrey', DateTime(2026, 8, 4), 226, 181),
    _trip('t2', 'Monterrey', 'Saltillo', DateTime(2026, 8, 3), 88, 152),
    _trip('t3', 'Monterrey', 'Reynosa', DateTime(2026, 8, 2), 226, 210),
    _trip('t4', 'Saltillo', 'Monterrey', DateTime(2026, 8), 88, 168),
  ];

  final profile = OperatorProfile(
    id: 'op-1',
    employeeNumber: '12345',
    fullName: 'Juan Ramírez Solís',
    startDate: DateTime(2022, 1, 15),
    level: OperatorLevel.oro,
    totalPoints: 11240,
    availablePoints: 3200,
  );

  final homeState = HomeStateDashboard(
    monthTrips: trips,
    totalKm: 628,
    totalPoints: 711,
    streak: 4,
  );

  for (final (name, brightness) in modernistThemes) {
    testWidgets('Inicio sin viaje coincide con el export $name',
        (tester) async {
      await setUpModernistGolden(tester);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: IdleHomeScreen(profile: profile, homeState: homeState),
          ),
        ),
      );

      // Medio segundo para que el balanceo y el hint salgan de su reposo.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(IdleHomeScreen),
        matchesGoldenFile('goldens/idle_home_${name}_almacen.png'),
      );

      // Segunda sección: se llega deslizando hacia arriba.
      await tester.fling(find.byType(PageView), const Offset(0, -400), 1000);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(IdleHomeScreen),
        matchesGoldenFile('goldens/idle_home_${name}_detalle.png'),
      );
    });
  }
}

Trip _trip(
  String id,
  String origen,
  String destino,
  DateTime end,
  double km,
  int puntos,
) =>
    Trip(
      id: id,
      operadorId: 'op-1',
      origen: origen,
      destino: destino,
      estado: TripStatus.completado,
      createdAt: end,
      updatedAt: end,
      fechaFin: end,
      kmRecorridos: km,
      puntosObtenidos: puntos,
    );
