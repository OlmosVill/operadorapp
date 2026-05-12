// Jerarquía de errores tipados del dominio.
// Usar en use cases: Either<AppError, T>
sealed class AppError {
  const AppError();
}

final class NetworkError extends AppError {
  const NetworkError({this.message});

  final String? message;
}

final class AuthError extends AppError {
  const AuthError({required this.message});

  final String message;
}

final class NotFoundError extends AppError {
  const NotFoundError({this.resource});

  final String? resource;
}

final class ValidationError extends AppError {
  const ValidationError({required this.message});

  final String message;
}

final class ServerError extends AppError {
  const ServerError({required this.statusCode, this.message});

  final int statusCode;
  final String? message;
}

final class UnexpectedError extends AppError {
  const UnexpectedError({this.error, this.stackTrace});

  final Object? error;
  final StackTrace? stackTrace;
}
