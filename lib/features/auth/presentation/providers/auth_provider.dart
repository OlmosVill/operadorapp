import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:operadorapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:operadorapp/features/auth/domain/entities/operator_session.dart';
import 'package:operadorapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:operadorapp/features/auth/domain/usecases/login_usecase.dart';
import 'package:operadorapp/features/auth/domain/usecases/logout_usecase.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => SupabaseAuthDatasource(ref.read(supabaseClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDatasource: ref.read(authRemoteDatasourceProvider),
    logger: ref.read(loggerProvider),
  ),
);

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.read(authRepositoryProvider)),
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.read(authRepositoryProvider)),
);

// Stream del estado de autenticación — persiste mientras la app viva
final authStateProvider = StreamProvider<OperatorSession>(
  (ref) => ref.read(authRepositoryProvider).watchAuthState(),
);

// Notifier para el proceso de login (muestra loading y errores)
class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  LoginNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> login({
    required String employeeNumber,
    required String password,
  }) async {
    state = const AsyncLoading();

    final result = await _ref.read(loginUseCaseProvider).call(
          employeeNumber: employeeNumber,
          password: password,
        );

    state = result.fold(
      (error) => AsyncError(_errorMessage(error), StackTrace.current),
      (_) => const AsyncData(null),
    );
  }

  void clearError() => state = const AsyncData(null);

  String _errorMessage(AppError error) => switch (error) {
        ValidationError(:final message) => message,
        AuthError(:final message) => message,
        NetworkError() => 'Sin conexión. Verifica tu red.',
        _ => 'Error inesperado. Intenta de nuevo.',
      };
}

final loginNotifierProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, AsyncValue<void>>(
  LoginNotifier.new,
);

class LogoutNotifier extends StateNotifier<AsyncValue<void>> {
  LogoutNotifier(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<void> logout() async {
    state = const AsyncLoading();
    final result = await _ref.read(logoutUseCaseProvider).call();
    state = result.fold(
      (_) => const AsyncError('No se pudo cerrar sesión', StackTrace.empty),
      (_) => const AsyncData(null),
    );
  }
}

final logoutNotifierProvider =
    StateNotifierProvider.autoDispose<LogoutNotifier, AsyncValue<void>>(
  LogoutNotifier.new,
);
