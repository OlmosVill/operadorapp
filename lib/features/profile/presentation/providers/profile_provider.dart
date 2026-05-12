import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:operadorapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:operadorapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:operadorapp/features/profile/domain/usecases/get_profile_usecase.dart';

final profileRemoteDatasourceProvider = Provider<ProfileRemoteDatasource>(
  (ref) => SupabaseProfileDatasource(ref.read(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    remoteDatasource: ref.read(profileRemoteDatasourceProvider),
    logger: ref.read(loggerProvider),
  ),
);

final getProfileUseCaseProvider = Provider<GetProfileUseCase>(
  (ref) => GetProfileUseCase(ref.read(profileRepositoryProvider)),
);

// TODO(fase-2): Cambiar estrategia a offline-first:
//   1. Leer primero de Drift (respuesta instantánea sin red)
//   2. Lanzar sync con Supabase en background
//   3. Actualizar Drift con datos frescos → Riverpod notifica a la UI
// El throw StateError es un workaround temporal; en Fase 2 se propagará
// el AppError tipado directamente desde el repositorio local de Drift.
final profileProvider = FutureProvider<OperatorProfile>((ref) async {
  final authState = await ref.watch(authStateProvider.future);

  if (!authState.isAuthenticated) {
    throw Exception('No autenticado');
  }

  final result = await ref.read(getProfileUseCaseProvider).call(
        authUserId: authState.operatorId,
      );

  return result.fold(
    (error) => throw StateError(error.toString()),
    (profile) => profile,
  );
});
