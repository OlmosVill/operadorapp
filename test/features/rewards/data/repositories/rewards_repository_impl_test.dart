import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/core/services/sync_service.dart';
import 'package:operadorapp/features/rewards/data/datasources/rewards_local_datasource.dart';
import 'package:operadorapp/features/rewards/data/datasources/rewards_remote_datasource.dart';
import 'package:operadorapp/features/rewards/data/repositories/rewards_repository_impl.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';

class MockRewardsLocal extends Mock implements RewardsLocalDatasource {}

class MockRewardsRemote extends Mock implements RewardsRemoteDatasource {}

class MockSyncService extends Mock implements SyncService {}

void main() {
  late RewardsRepositoryImpl sut;
  late MockRewardsLocal mockLocal;
  late MockRewardsRemote mockRemote;
  late MockSyncService mockSync;

  const tOperadorId = 'operador-uuid-001';

  final tPremios = [
    const Premio(
      id: 'premio-001',
      nombre: r'Tarjeta $500',
      tipo: PremioTipo.tarjetaRegalo,
      costoPuntos: 1000,
      activo: true,
    ),
  ];

  final tCanje = Canje(
    id: 'canje-001',
    operadorId: tOperadorId,
    premioId: 'premio-001',
    puntosCanjeados: 1000,
    estado: CanjeEstado.solicitado,
    fechaSolicitud: DateTime(2025, 6),
    updatedAt: DateTime(2025, 6),
  );

  setUpAll(() {
    registerFallbackValue(tCanje);
  });

  setUp(() {
    mockLocal = MockRewardsLocal();
    mockRemote = MockRewardsRemote();
    mockSync = MockSyncService();
    when(() => mockSync.syncCatalogo()).thenAnswer((_) async {});
    when(() => mockSync.syncCanjes(any())).thenAnswer((_) async {});
    sut = RewardsRepositoryImpl(mockLocal, mockRemote, mockSync);
  });

  group('RewardsRepositoryImpl.watchCatalogo —', () {
    test('emite Right(premios) cuando el datasource emite datos', () {
      when(
        () => mockLocal.watchCatalogo(),
      ).thenAnswer((_) => Stream.value(tPremios));

      expect(
        sut.watchCatalogo(),
        emits(Right<AppError, List<Premio>>(tPremios)),
      );
    });

    test('emite Left(UnexpectedError) cuando el datasource lanza excepción',
        () {
      when(
        () => mockLocal.watchCatalogo(),
      ).thenAnswer((_) => Stream.error(Exception('DB error')));

      expect(
        sut.watchCatalogo(),
        emits(
          isA<Left<AppError, List<Premio>>>().having(
            (l) => l.value,
            'error',
            isA<UnexpectedError>(),
          ),
        ),
      );
    });

    test('emite Right([]) cuando el datasource emite lista vacía', () {
      when(
        () => mockLocal.watchCatalogo(),
      ).thenAnswer((_) => Stream.value([]));

      expect(
        sut.watchCatalogo(),
        emits(
          isA<Right<AppError, List<Premio>>>()
              .having((r) => r.value, 'value', isEmpty),
        ),
      );
    });
  });

  group('RewardsRepositoryImpl.canjearPremio —', () {
    test('retorna Right(canje) cuando el remote tiene éxito', () async {
      when(
        () => mockRemote.canjearPremio(
          premioId: any(named: 'premioId'),
          operadorId: any(named: 'operadorId'),
        ),
      ).thenAnswer((_) async => tCanje);

      when(
        () => mockLocal.upsertCanje(any()),
      ).thenAnswer((_) async {});

      final result = await sut.canjearPremio(
        premioId: 'premio-001',
        operadorId: tOperadorId,
      );

      expect(result, Right<AppError, Canje>(tCanje));
    });

    test('retorna Left(UnexpectedError) cuando el remote lanza excepción',
        () async {
      when(
        () => mockRemote.canjearPremio(
          premioId: any(named: 'premioId'),
          operadorId: any(named: 'operadorId'),
        ),
      ).thenThrow(Exception('Puntos insuficientes'));

      final result = await sut.canjearPremio(
        premioId: 'premio-001',
        operadorId: tOperadorId,
      );

      expect(
        result,
        isA<Left<AppError, Canje>>().having(
          (l) => l.value,
          'error',
          isA<UnexpectedError>(),
        ),
      );
    });
  });
}
