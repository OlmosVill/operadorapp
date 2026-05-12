import 'package:flutter/material.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/core/theme/app_colors.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    required this.error,
    super.key,
    this.onRetry,
  });

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final message = _messageFor(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.textSecondaryDark,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _messageFor(Object error) {
    if (error is NetworkError) {
      return 'Sin conexión. Verifica tu red e intenta de nuevo.';
    }
    if (error is NotFoundError) {
      return 'No se encontró la información solicitada.';
    }
    if (error is AuthError) {
      return error.message;
    }
    return 'Ocurrió un error inesperado.';
  }
}
