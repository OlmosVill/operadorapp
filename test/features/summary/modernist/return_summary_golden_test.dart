import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/summary/domain/entities/return_summary.dart';
import 'package:operadorapp/features/summary/presentation/widgets/modernist/return_summary_dialog.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';

import '../../trips/modernist/modernist_golden_harness.dart';

/// Compara «Resumen Regreso» contra su export, en los dos temas.
///
/// ```sh
/// flutter test --update-goldens test/features/summary/modernist
/// ```
void main() {
  final summary = ReturnSummary(
    completedTrips: [
      _trip('t1', 'Monterrey', 'Saltillo', 88, 152),
      _trip('t2', 'Saltillo', 'Reynosa', 226, 181),
      _trip('t3', 'Reynosa', 'Monterrey', 226, 210),
    ],
    pointsBefore: 10697,
    pointsAfter: 11240,
    levelBefore: OperatorLevel.oro,
    levelAfter: OperatorLevel.oro,
    since: DateTime(2026, 8, 4, 19, 40),
    rankBefore: 9,
    rankAfter: 7,
  );

  for (final (name, brightness) in modernistThemes) {
    testWidgets('Resumen de regreso coincide con el export $name',
        (tester) async {
      await setUpModernistGolden(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: ModernistReturnSummaryDialog(summary: summary),
        ),
      );

      // El contador y la barra tardan ~1.1 s en asentarse.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 1400));

      await expectLater(
        find.byType(ModernistReturnSummaryDialog),
        matchesGoldenFile('goldens/return_summary_$name.png'),
      );
    });
  }
}

Trip _trip(String id, String origen, String destino, double km, int puntos) =>
    Trip(
      id: id,
      operadorId: 'op-1',
      origen: origen,
      destino: destino,
      estado: TripStatus.completado,
      createdAt: DateTime(2026, 8, 5),
      updatedAt: DateTime(2026, 8, 5),
      fechaFin: DateTime(2026, 8, 5),
      kmRecorridos: km,
      puntosObtenidos: puntos,
    );
