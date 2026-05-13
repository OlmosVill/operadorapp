import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:operadorapp/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:operadorapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:operadorapp/features/profile/domain/usecases/get_profile_usecase.dart';

// ─── Datasources & Repository ────────────────────────────────────────────────

final profileLocalDatasourceProvider = Provider<ProfileLocalDatasource>(
  (ref) => DriftProfileLocalDatasource(ref.read(appDatabaseProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    localDatasource: ref.read(profileLocalDatasourceProvider),
    syncService: ref.read(syncServiceProvider),
    logger: ref.read(loggerProvider),
  ),
);

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.read(profileRepositoryProvider)),
);

// ─── Perfil reactivo offline-first ────────────────────────────────────────────
//
// StreamProvider que observa Drift directamente: cualquier escritura del
// SyncService en la tabla local desencadena una actualización en la UI.
final profileProvider = StreamProvider<OperatorProfile>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final authUserId = authAsync.value?.operatorId ?? '';

  if (authUserId.isEmpty) return const Stream.empty();

  return ref
      .read(profileRepositoryProvider)
      .watchProfile(authUserId: authUserId)
      .map(
        (result) => result.fold(
          (error) => throw Exception(error.toString()),
          (profile) => profile,
        ),
      );
});
