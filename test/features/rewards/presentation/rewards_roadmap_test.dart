import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/screens/rewards_roadmap_screen.dart';

void main() {
  // Premios desordenados para probar el sort
  final premios = [
    const Premio(
      id: 'p3',
      nombre: 'Premio C',
      tipo: PremioTipo.experiencia,
      costoPuntos: 2000,
      activo: true,
    ),
    const Premio(
      id: 'p1',
      nombre: 'Premio A',
      tipo: PremioTipo.producto,
      costoPuntos: 500,
      activo: true,
      nivelMinimo: OperatorLevel.plata,
    ),
    const Premio(
      id: 'p2',
      nombre: 'Premio B',
      tipo: PremioTipo.tarjetaRegalo,
      costoPuntos: 1000,
      activo: true,
      nivelMinimo: OperatorLevel.oro,
    ),
  ];

  group('filterAndSortPremios —', () {
    test('ordena por costoPuntos ascendente', () {
      final result = filterAndSortPremios(premios, null);

      expect(
        result.map((p) => p.costoPuntos).toList(),
        [500, 1000, 2000],
      );
    });

    test(
        'filtra por nivel e incluye premios sin nivelMinimo',
        () {
      final result =
          filterAndSortPremios(premios, OperatorLevel.plata);

      // p1 (plata) + p3 (null nivelMinimo) = 2 resultados
      expect(result.length, 2);
      expect(
        result.every(
          (p) =>
              p.nivelMinimo == null ||
              p.nivelMinimo == OperatorLevel.plata,
        ),
        isTrue,
      );
    });

    test('devuelve todos los premios cuando el filtro es null',
        () {
      final result = filterAndSortPremios(premios, null);

      expect(result.length, premios.length);
    });
  });
}
