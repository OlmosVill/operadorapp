import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:operadorapp/features/rewards/presentation/screens/modernist/rewards_route_screen.dart';

import '../../trips/modernist/modernist_golden_harness.dart';

/// Compara «Premios Ruta» contra su export, en los dos temas.
///
/// ```sh
/// flutter test --update-goldens test/features/rewards/modernist
/// ```
void main() {
  // El catálogo del export, que es el de supabase/seed.sql.
  const catalogo = [
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
      id: 'despensa',
      nombre: 'Despensa familiar completa',
      tipo: PremioTipo.producto,
      costoPuntos: 5000,
      activo: true,
      nivelMinimo: OperatorLevel.oro,
    ),
    Premio(
      id: 'herramientas',
      nombre: 'Set de herramientas profesional',
      tipo: PremioTipo.producto,
      costoPuntos: 8000,
      activo: true,
      nivelMinimo: OperatorLevel.oro,
    ),
    Premio(
      id: 'tablet',
      nombre: 'Tablet educativa',
      tipo: PremioTipo.producto,
      costoPuntos: 12000,
      activo: true,
      nivelMinimo: OperatorLevel.oro,
    ),
    Premio(
      id: 'smartphone',
      nombre: 'Smartphone de gama media',
      tipo: PremioTipo.producto,
      costoPuntos: 18000,
      activo: true,
      nivelMinimo: OperatorLevel.platino,
    ),
    Premio(
      id: 'moto',
      nombre: 'Motocicleta de trabajo',
      tipo: PremioTipo.vehiculo,
      costoPuntos: 60000,
      activo: true,
      nivelMinimo: OperatorLevel.esmeralda,
    ),
  ];

  final profile = OperatorProfile(
    id: 'op-1',
    employeeNumber: '12345',
    fullName: 'Juan Ramírez Solís',
    startDate: DateTime(2022),
    level: OperatorLevel.oro,
    totalPoints: 11240,
    availablePoints: 8740,
  );

  group('buildRewardRoute', () {
    test('ordena de más caro arriba a más barato abajo', () {
      final rows = buildRewardRoute(
        premios: catalogo,
        level: OperatorLevel.oro,
        available: 8740,
      );

      final costs = rows
          .whereType<RewardRouteMilestone>()
          .map((m) => m.premio.costoPuntos)
          .toList();

      expect(costs, [60000, 18000, 12000, 8000, 5000, 2500, 500]);
    });

    test('cierra la ruta con el marcador del operador', () {
      final rows = buildRewardRoute(
        premios: catalogo,
        level: OperatorLevel.oro,
        available: 8740,
      );

      expect(rows.last, isA<RewardRouteMarker>());
      expect((rows.last as RewardRouteMarker).balance, 8740);
    });

    test('clasifica cada hito contra nivel y saldo', () {
      final rows = buildRewardRoute(
        premios: catalogo,
        level: OperatorLevel.oro,
        available: 8740,
      ).whereType<RewardRouteMilestone>().toList();

      MilestoneState stateOf(String id) =>
          rows.firstWhere((m) => m.premio.id == id).state;

      // Alcanza saldo y nivel.
      expect(stateOf('herramientas'), MilestoneState.open);
      // Nivel oro no llega a platino ni esmeralda.
      expect(stateOf('smartphone'), MilestoneState.locked);
      expect(stateOf('moto'), MilestoneState.locked);
      // El más barato que todavía no alcanza es el objetivo.
      expect(stateOf('tablet'), MilestoneState.target);
    });

    test('el filtro por nivel deja solo ese tramo', () {
      final rows = buildRewardRoute(
        premios: catalogo,
        level: OperatorLevel.oro,
        available: 8740,
        filter: OperatorLevel.oro,
      ).whereType<RewardRouteMilestone>().toList();

      expect(
        rows.map((m) => m.premio.id),
        ['tablet', 'herramientas', 'despensa'],
      );
    });
  });

  for (final (name, brightness) in modernistThemes) {
    testWidgets('Premios Ruta coincide con el export $name', (tester) async {
      await setUpModernistGolden(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith((ref) => Stream.value(profile)),
            premiosProvider.overrideWith((ref) => Stream.value(catalogo)),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const RewardsRouteScreen(),
          ),
        ),
      );

      // Varios frames: el salto al marcador reintenta hasta tocar fondo.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // La pantalla abre desplazada al final, donde está el operador.
      await expectLater(
        find.byType(RewardsRouteScreen),
        matchesGoldenFile('goldens/rewards_route_$name.png'),
      );
    });
  }
}
