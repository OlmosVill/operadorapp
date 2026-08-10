import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';
import 'package:operadorapp/features/points/presentation/providers/points_provider.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trips/presentation/screens/modernist/trips_screen.dart';

import 'modernist_golden_harness.dart';

/// Compara «Viajes» contra su export, en los dos temas.
///
/// ```sh
/// flutter test --update-goldens test/features/trips/modernist
/// ```
void main() {
  // El dataset del export, con sus mismos estados y meses.
  final trips = [
    _trip(
      id: '1842',
      origen: 'Monterrey',
      destino: 'Guadalajara',
      start: DateTime(2026, 8, 4),
      estado: TripStatus.enCurso,
      km: 486,
      rendimiento: 4.6,
    ),
    _trip(
      id: '1836',
      origen: 'Saltillo',
      destino: 'Monterrey',
      start: DateTime(2026, 8),
      estado: TripStatus.completado,
      km: 88,
      rendimiento: 5.1,
      calificacion: 4.8,
      puntos: 168,
    ),
    _trip(
      id: '1829',
      origen: 'Monterrey',
      destino: 'Nuevo Laredo',
      start: DateTime(2026, 7, 29),
      estado: TripStatus.completado,
      km: 224,
      rendimiento: 4.8,
      calificacion: 4.5,
      puntos: 148,
    ),
    _trip(
      id: '1824',
      origen: 'Monterrey',
      destino: 'Torreón',
      start: DateTime(2026, 7, 27),
      estado: TripStatus.incidente,
      km: 312,
      rendimiento: 4.1,
    ),
    _trip(
      id: '1802',
      origen: 'Torreón',
      destino: 'Monterrey',
      start: DateTime(2026, 7, 14),
      estado: TripStatus.cancelado,
    ),
  ];

  // Descripción tal como la deja la Edge Function `calcular-puntos-viaje`.
  final movements = [
    PointMovement(
      id: 'mv-1836',
      operadorId: 'op-1',
      tipo: MovementType.ganadoViaje,
      puntos: 168,
      saldoDespues: 3368,
      createdAt: DateTime(2026, 8),
      viajeId: '1836',
      descripcion: 'Viaje completado. rendimiento: +113, puntualidad: +50, '
          'sin_reportes_mantenimiento: +30, alertas_seguridad: 0, '
          'incidencias: -25',
    ),
  ];

  group('parsePointsBreakdown', () {
    test('rescata el desglose del formato de la Edge Function', () {
      final rows = parsePointsBreakdown(movements.first.descripcion);

      expect(rows.map((r) => r.points).toList(), [113, 50, 30, 0, -25]);
      expect(rows.first.label, 'Rendimiento vs. esperado');
      expect(rows.last.label, 'Incidencias');
    });

    test('devuelve vacío con el formato que escribe el trigger', () {
      // fn_calcular_puntos_viaje no guarda el desglose por regla.
      final rows = parsePointsBreakdown(
        'Viaje completado — 486 km, calif 4.8, 1 alertas, 0 incidencias',
      );

      expect(rows, isEmpty);
    });

    test('tolera una descripción ausente', () {
      expect(parsePointsBreakdown(null), isEmpty);
    });
  });

  for (final (name, brightness) in modernistThemes) {
    testWidgets('Viajes coincide con el export $name', (tester) async {
      await setUpModernistGolden(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripsProvider.overrideWith((ref) => Stream.value(trips)),
            movementsProvider.overrideWith((ref) => Stream.value(movements)),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const ModernistTripsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(ModernistTripsScreen),
        matchesGoldenFile('goldens/trips_$name.png'),
      );

      // La hoja del viaje cerrado, que es la que trae desglose.
      await tester.tap(find.text('Saltillo → Monterrey'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(ModernistTripsScreen),
        matchesGoldenFile('goldens/trips_${name}_hoja.png'),
      );
    });
  }
}

Trip _trip({
  required String id,
  required String origen,
  required String destino,
  required DateTime start,
  required TripStatus estado,
  double? km,
  double? rendimiento,
  double? calificacion,
  int puntos = 0,
}) =>
    Trip(
      id: id,
      operadorId: 'op-1',
      origen: origen,
      destino: destino,
      estado: estado,
      createdAt: start,
      updatedAt: start,
      fechaInicio: start,
      fechaFin: estado == TripStatus.completado ? start : null,
      kmRecorridos: km,
      rendimientoReal: rendimiento,
      calificacion: calificacion,
      puntosObtenidos: puntos,
    );
