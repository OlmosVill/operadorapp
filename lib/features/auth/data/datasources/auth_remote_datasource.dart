import 'package:operadorapp/core/constants/app_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRemoteDatasource {
  Future<AuthResponse> signIn({
    required String employeeNumber,
    required String password,
  });

  Future<void> signOut();

  Session? getCurrentSession();

  Future<void> sendPasswordResetEmail({required String employeeNumber});

  Stream<AuthState> watchAuthState();
}

final class SupabaseAuthDatasource implements AuthRemoteDatasource {
  const SupabaseAuthDatasource(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthResponse> signIn({
    required String employeeNumber,
    required String password,
  }) {
    final email = '$employeeNumber${AppConstants.authEmailSuffix}';
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  // TODO(fase-8): Al hacer signOut, primero desregistrar el FCM/APNs token
  // del operador en Supabase para dejar de recibir push notifications.
  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Session? getCurrentSession() => _client.auth.currentSession;

  @override
  Future<void> sendPasswordResetEmail({required String employeeNumber}) {
    final email = '$employeeNumber${AppConstants.authEmailSuffix}';
    return _client.auth.resetPasswordForEmail(email);
  }

  @override
  Stream<AuthState> watchAuthState() => _client.auth.onAuthStateChange;
}
