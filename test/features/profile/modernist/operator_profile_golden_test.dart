import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/profile/presentation/screens/modernist/operator_profile_screen.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trucks/domain/entities/truck.dart';
import 'package:operadorapp/features/trucks/presentation/providers/trucks_provider.dart';

import '../../trips/modernist/modernist_golden_harness.dart';

/// Compara «Perfil Operador» contra su export, en los dos temas.
///
/// ```sh
/// flutter test --update-goldens test/features/profile/modernist
/// ```
void main() {
  final profile = OperatorProfile(
    id: 'op-1',
    employeeNumber: '12345',
    fullName: 'Juan Ramírez Solís',
    startDate: DateTime(2022),
    level: OperatorLevel.oro,
    totalPoints: 11240,
    availablePoints: 8740,
    base: 'Monterrey',
  );

  // El catálogo del export, con su mezcla de alcanzable, lejano y bloqueado.
  const premios = [
    Premio(
      id: 'tarjeta500',
      nombre: r'Tarjeta de regalo $500',
      tipo: PremioTipo.tarjetaRegalo,
      costoPuntos: 500,
      activo: true,
    ),
    Premio(
      id: 'mochila',
      nombre: 'Mochila escolar premium',
      tipo: PremioTipo.producto,
      costoPuntos: 2500,
      activo: true,
    ),
    Premio(
      id: 'smartphone',
      nombre: 'Smartphone de gama media',
      tipo: PremioTipo.producto,
      costoPuntos: 18000,
      activo: true,
      nivelMinimo: OperatorLevel.platino,
    ),
  ];

  final trucks = [
    TruckSummary(
      tractoId: 't-003',
      historialId: 'h-1',
      numeroEconomico: 'T-003',
      kmRecorridos: 84200,
      viajesRealizados: 184,
      esActual: true,
      fechaInicio: DateTime(2022),
      marca: 'Freightliner',
      modelo: 'Cascadia',
    ),
  ];

  final trips = [
    for (var i = 0; i < 184; i++)
      Trip(
        id: 't$i',
        operadorId: 'op-1',
        origen: 'Monterrey',
        destino: 'Saltillo',
        estado: TripStatus.completado,
        createdAt: DateTime(2026, 7, 1 + (i % 28)),
        updatedAt: DateTime(2026, 7, 1 + (i % 28)),
        rendimientoReal: 4.6,
      ),
  ];

  for (final (name, brightness) in modernistThemes) {
    testWidgets('Perfil coincide con el export $name', (tester) async {
      await setUpModernistGolden(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) => Stream.value(profile)),
            premiosProvider.overrideWith((ref) => Stream.value(premios)),
            tripsProvider.overrideWith((ref) => Stream.value(trips)),
            truckSummariesProvider.overrideWith((ref) => Stream.value(trucks)),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const OperatorProfileScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      await expectLater(
        find.byType(OperatorProfileScreen),
        matchesGoldenFile('goldens/operator_profile_$name.png'),
      );
    });
  }
}
