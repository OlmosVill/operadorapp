import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';
import 'package:operadorapp/features/ranking/presentation/providers/ranking_provider.dart';
import 'package:operadorapp/features/ranking/presentation/screens/modernist/ranking_screen.dart';

import '../../trips/modernist/modernist_golden_harness.dart';

/// Compara «Ranking» contra su export, en los dos temas.
///
/// ```sh
/// flutter test --update-goldens test/features/ranking/modernist
/// ```
void main() {
  // El corte global del export, con su mezcla de subidas, bajadas y un alta.
  // (id, nombre, nivel, puntos, posición anterior)
  const raw = <(String, String, OperatorLevel, int, int?)>[
    ('op-11', 'Ricardo Salinas Mora', OperatorLevel.diamante, 62410, 1),
    ('op-04', 'María Fernanda Ochoa', OperatorLevel.diamante, 60180, 3),
    ('op-02', 'Gerardo Núñez Pineda', OperatorLevel.esmeralda, 48920, 2),
    ('op-09', 'Ana Lucía Treviño', OperatorLevel.esmeralda, 41350, 4),
    ('op-15', 'Óscar Beltrán Ríos', OperatorLevel.esmeralda, 33700, 8),
    ('op-03', 'Hugo Cantú Villarreal', OperatorLevel.platino, 24880, 6),
    ('op-07', 'Juan Ramírez Solís', OperatorLevel.oro, 11240, 9),
    ('op-12', 'Sergio Aguilar Peña', OperatorLevel.oro, 10980, 7),
    ('op-06', 'Diana Karina Robles', OperatorLevel.oro, 9420, 10),
    ('op-14', 'Paola Estrada Lira', OperatorLevel.plata, 2910, null),
  ];

  final entries = [
    for (final (i, row) in raw.indexed)
      _entry(row.$1, row.$2, row.$3, row.$4, i + 1, row.$5),
  ];

  for (final (name, brightness) in modernistThemes) {
    testWidgets('Ranking coincide con el export $name', (tester) async {
      await setUpModernistGolden(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rankingProvider.overrideWith((ref) => Stream.value(entries)),
            // El operador de la sesión es el séptimo: su fila va resaltada.
            myRankingEntryProvider.overrideWithValue(entries[6]),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const ModernistRankingScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(ModernistRankingScreen),
        matchesGoldenFile('goldens/ranking_$name.png'),
      );
    });
  }
}

RankingEntry _entry(
  String id,
  String nombre,
  OperatorLevel nivel,
  int puntos,
  int posicion,
  int? anterior,
) =>
    RankingEntry(
      operadorId: id,
      numeroEmpleado: id.replaceAll('op-', ''),
      nombreCompleto: nombre,
      nivel: nivel,
      puntos: puntos,
      viajesCompletados: 100 + posicion,
      posicion: posicion,
      calificacion: 4.9 - posicion * 0.05,
      posicionAnterior: anterior,
    );
