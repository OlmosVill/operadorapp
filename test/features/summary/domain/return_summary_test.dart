import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/profile/domain/entities/level_thresholds.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/summary/domain/entities/return_summary.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';

Trip _trip({
  String id = 't1',
  int puntos = 100,
  double? km = 500,
}) =>
    Trip(
      id: id,
      operadorId: 'op-1',
      origen: 'Monterrey',
      destino: 'CDMX',
      estado: TripStatus.completado,
      createdAt: DateTime(2026, 8, 3),
      updatedAt: DateTime(2026, 8, 4),
      kmRecorridos: km,
      puntosObtenidos: puntos,
    );

ReturnSummary _summary({
  List<Trip> trips = const [],
  int pointsBefore = 0,
  int pointsAfter = 0,
  OperatorLevel levelBefore = OperatorLevel.plata,
  OperatorLevel levelAfter = OperatorLevel.plata,
  int? rankBefore,
  int? rankAfter,
}) =>
    ReturnSummary(
      completedTrips: trips,
      pointsBefore: pointsBefore,
      pointsAfter: pointsAfter,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      since: DateTime(2026, 8, 2),
      rankBefore: rankBefore,
      rankAfter: rankAfter,
    );

void main() {
  group('ReturnSummary.pointsEarned', () {
    test('se deriva del acumulado, no de la suma de viajes', () {
      final s = _summary(pointsBefore: 1000, pointsAfter: 1450);

      expect(s.pointsEarned, 450);
    });

    test('es cero cuando no cambió el acumulado', () {
      expect(_summary().pointsEarned, 0);
    });
  });

  group('ReturnSummary.rankDelta', () {
    test('positivo al subir lugares', () {
      expect(_summary(rankBefore: 8, rankAfter: 5).rankDelta, 3);
    });

    test('negativo al bajar lugares', () {
      expect(_summary(rankBefore: 4, rankAfter: 7).rankDelta, -3);
    });

    test('null si falta alguno de los dos datos', () {
      expect(_summary(rankAfter: 5).rankDelta, isNull);
      expect(_summary(rankBefore: 5).rankDelta, isNull);
    });
  });

  group('ReturnSummary.leveledUp', () {
    test('detecta el ascenso de nivel', () {
      final s = _summary(levelAfter: OperatorLevel.oro);

      expect(s.leveledUp, isTrue);
    });

    test('no marca ascenso si el nivel no cambió', () {
      expect(_summary().leveledUp, isFalse);
    });
  });

  group('ReturnSummary.hasContent', () {
    test('sin nada que contar no se abre el popup', () {
      expect(_summary(rankBefore: 5, rankAfter: 5).hasContent, isFalse);
    });

    test('basta un viaje completado', () {
      expect(_summary(trips: [_trip()]).hasContent, isTrue);
    });

    test('basta un cambio de puntos', () {
      expect(_summary(pointsAfter: 1200).hasContent, isTrue);
    });

    test('basta un cambio de lugar', () {
      expect(_summary(rankBefore: 6, rankAfter: 5).hasContent, isTrue);
    });
  });

  group('ReturnSummary.totalKm', () {
    test('suma los km de los viajes e ignora los nulos', () {
      final s = _summary(
        trips: [
          _trip(id: 'a', km: 300),
          _trip(id: 'b', km: 250.5),
          _trip(id: 'c', km: null),
        ],
      );

      expect(s.totalKm, 550.5);
    });
  });

  group('Progreso de nivel', () {
    test('pointsToNextLevel usa el umbral del nivel alcanzado', () {
      final s = _summary(pointsBefore: 4000, pointsAfter: 4800);

      // Oro arranca en 5000
      expect(s.pointsToNextLevel, 200);
    });

    test('nunca devuelve negativo si ya rebasó el umbral', () {
      final s = _summary(pointsAfter: 9000);

      expect(s.pointsToNextLevel, 0);
    });

    test('es null en el nivel máximo', () {
      final s = _summary(
        pointsAfter: 90000,
        levelAfter: OperatorLevel.diamante,
      );

      expect(s.pointsToNextLevel, isNull);
      expect(s.progressAfter, 1);
    });

    test('la barra avanza dentro del rango del nivel', () {
      final s = _summary(
        pointsBefore: 5000,
        pointsAfter: 10000,
        levelBefore: OperatorLevel.oro,
        levelAfter: OperatorLevel.oro,
      );

      // Oro va de 5000 a 15000: 10000 es la mitad del tramo
      expect(s.progressBefore, 0);
      expect(s.progressAfter, closeTo(0.5, 0.001));
    });
  });

  group('levelForPoints', () {
    test('mapea el acumulado al nivel correcto', () {
      expect(levelForPoints(0), OperatorLevel.plata);
      expect(levelForPoints(4999), OperatorLevel.plata);
      expect(levelForPoints(5000), OperatorLevel.oro);
      expect(levelForPoints(29999), OperatorLevel.platino);
      expect(levelForPoints(60000), OperatorLevel.diamante);
    });
  });
}
