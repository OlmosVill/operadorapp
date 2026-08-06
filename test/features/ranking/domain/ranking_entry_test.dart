import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';

RankingEntry _entry({required int posicion, int? posicionAnterior}) =>
    RankingEntry(
      operadorId: 'op-1',
      numeroEmpleado: '12345',
      nombreCompleto: 'Juan Pérez López',
      nivel: OperatorLevel.oro,
      puntos: 1200,
      viajesCompletados: 8,
      posicion: posicion,
      posicionAnterior: posicionAnterior,
    );

void main() {
  group('RankingEntry.trend', () {
    test('subió lugares cuando la posición anterior era mayor', () {
      final entry = _entry(posicion: 3, posicionAnterior: 5);

      expect(entry.trend, RankingTrend.subio);
      expect(entry.lugaresMovidos, 2);
      expect(entry.lugaresMovidosAbs, 2);
    });

    test('bajó lugares cuando la posición anterior era menor', () {
      final entry = _entry(posicion: 7, posicionAnterior: 4);

      expect(entry.trend, RankingTrend.bajo);
      expect(entry.lugaresMovidos, -3);
      expect(entry.lugaresMovidosAbs, 3);
    });

    test('igual cuando la posición no cambió', () {
      final entry = _entry(posicion: 2, posicionAnterior: 2);

      expect(entry.trend, RankingTrend.igual);
      expect(entry.lugaresMovidos, 0);
    });

    test('nuevo cuando no hay snapshot previo', () {
      final entry = _entry(posicion: 9);

      expect(entry.trend, RankingTrend.nuevo);
      expect(entry.lugaresMovidos, isNull);
      expect(entry.lugaresMovidosAbs, 0);
    });
  });

  group('RankingEntry.esPodio', () {
    test('es podio del lugar 1 al 3', () {
      expect(_entry(posicion: 1).esPodio, isTrue);
      expect(_entry(posicion: 3).esPodio, isTrue);
      expect(_entry(posicion: 4).esPodio, isFalse);
    });
  });

  group('RankingEntry.iniciales', () {
    test('toma la primera letra del nombre y del apellido', () {
      expect(_entry(posicion: 1).iniciales, 'JP');
    });
  });

  group('RankingPeriodo', () {
    test('mapea el valor que espera la RPC', () {
      expect(RankingPeriodo.global.value, 'global');
      expect(RankingPeriodo.mensual.value, 'mensual');
    });

    test('fromString cae en global ante un valor desconocido', () {
      expect(RankingPeriodoX.fromString('mensual'), RankingPeriodo.mensual);
      expect(RankingPeriodoX.fromString('xyz'), RankingPeriodo.global);
    });
  });
}
