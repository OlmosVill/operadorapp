import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/profile/presentation/screens/modernist/operator_profile_screen.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/domain/repositories/rewards_repository.dart';
import 'package:operadorapp/features/rewards/domain/usecases/canjear_usecase.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:operadorapp/features/rewards/presentation/screens/modernist/rewards_route_screen.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/modernist/redeem_flow.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trucks/presentation/providers/trucks_provider.dart';

import '../../trips/modernist/modernist_golden_harness.dart';

/// Repositorio que responde lo que le digan, sin tocar red ni Drift.
class _StubRepo implements RewardsRepository {
  _StubRepo(this._answer);

  final Either<AppError, Canje> _answer;

  @override
  Future<Either<AppError, Canje>> canjearPremio({
    required String premioId,
    required String operadorId,
  }) async =>
      _answer;

  @override
  Stream<Either<AppError, List<Canje>>> watchCanjes(String operadorId) =>
      const Stream.empty();

  @override
  Stream<Either<AppError, List<Premio>>> watchCatalogo() =>
      const Stream.empty();
}

void main() {
  const catalogo = [
    Premio(
      id: 'tarjeta500',
      nombre: r'Tarjeta de regalo $500',
      tipo: PremioTipo.tarjetaRegalo,
      costoPuntos: 500,
      activo: true,
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

  final canje = Canje(
    id: 'canje-1',
    operadorId: 'op-1',
    premioId: 'tarjeta500',
    puntosCanjeados: 500,
    estado: CanjeEstado.solicitado,
    fechaSolicitud: DateTime.utc(2026, 8, 10),
    updatedAt: DateTime.utc(2026, 8, 10),
  );

  Widget wrap(Widget screen, Either<AppError, Canje> answer) => ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) => Stream.value(profile)),
          premiosProvider.overrideWith((ref) => Stream.value(catalogo)),
          tripsProvider.overrideWith((ref) => const Stream.empty()),
          truckSummariesProvider.overrideWith((ref) => const Stream.empty()),
          canjearUsecaseProvider.overrideWithValue(
            CanjearUsecase(_StubRepo(answer)),
          ),
        ],
        child: MaterialApp(home: screen),
      );

  /// Los proveedores encadenados resuelven en varios frames: el perfil primero
  /// y el catálogo recién en el build siguiente.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapRedeem(WidgetTester tester) async {
    await tester.tap(find.text('CANJEAR').first);
    await settle(tester);
    await tester.tap(find.text('SÍ, CANJEAR'));
    await settle(tester);
  }

  final screens = <String, Widget>{
    'Premios Ruta': const RewardsRouteScreen(),
    'Perfil Operador': const OperatorProfileScreen(),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    group('$name —', () {
      testWidgets('un canje aceptado deja el acuse a la vista', (tester) async {
        await setUpModernistGolden(tester);
        await tester.pumpWidget(wrap(screen, Right(canje)));
        await settle(tester);

        await tapRedeem(tester);

        expect(find.text('CANJE REGISTRADO'), findsOneWidget);
        expect(find.text('CONFIRMAR CANJE'), findsNothing);
      });

      testWidgets('un canje rechazado dice por qué', (tester) async {
        await setUpModernistGolden(tester);
        await tester.pumpWidget(
          wrap(
            screen,
            const Left(
              ServerError(
                statusCode: 404,
                message: 'Premio no encontrado o inactivo',
              ),
            ),
          ),
        );
        await settle(tester);

        await tapRedeem(tester);

        expect(find.text('NO SE PUDO CANJEAR'), findsOneWidget);
        expect(find.text('Premio no encontrado o inactivo'), findsOneWidget);
        // El fallo silencioso era el bug: la hoja se cerraba sin más.
        expect(find.text('CANJE REGISTRADO'), findsNothing);
      });
    });
  }

  group('redeemErrorMessage —', () {
    test('prefiere el motivo del servidor', () {
      expect(
        redeemErrorMessage(
          const ServerError(statusCode: 402, message: 'Puntos insuficientes'),
        ),
        'Puntos insuficientes',
      );
    });

    test('cae en un texto genérico cuando no hay motivo', () {
      expect(
        redeemErrorMessage(const UnexpectedError()),
        contains('No se pudo registrar el canje'),
      );
      expect(
        redeemErrorMessage(const ServerError(statusCode: 500)),
        contains('No se pudo registrar el canje'),
      );
    });
  });
}
