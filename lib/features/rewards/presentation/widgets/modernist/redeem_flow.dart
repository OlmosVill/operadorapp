import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/errors/app_error.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/modernist/redeem_sheet.dart';

/// El canje visto desde la pantalla: confirmar, enviar y contar cómo salió.
///
/// «Perfil Operador» y «Premios Ruta» ofrecen el mismo canje, y la lógica
/// estaba copiada en las dos —con la diferencia de que Premios se tragaba el
/// fallo en silencio—. Vive aquí para que las dos se comporten igual.
mixin RedeemFlowMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Premio? _confirming;
  Premio? _done;
  Premio? _failed;
  String? _failure;
  bool _sending = false;

  /// Abre la hoja de confirmación para [premio].
  void startRedeem(Premio premio) => setState(() {
        _confirming = premio;
        _done = null;
        _failed = null;
        _failure = null;
      });

  void dismissRedeem() => setState(() {
        _confirming = null;
        _done = null;
        _failed = null;
        _failure = null;
      });

  Future<void> _submit(Premio premio, String operadorId) async {
    setState(() => _sending = true);
    final result = await ref.read(canjearUsecaseProvider).call(
          premioId: premio.id,
          operadorId: operadorId,
        );
    if (!mounted) return;

    setState(() {
      _sending = false;
      _confirming = null;
      result.fold(
        (error) {
          _failed = premio;
          _failure = redeemErrorMessage(error);
        },
        (_) => _done = premio,
      );
    });
  }

  /// La hoja que toque, o `null` si no hay ninguna abierta.
  ///
  /// [operadorId] es `operadores.id`, no el `auth_user_id`.
  Widget? buildRedeemSheet({
    required String operadorId,
    required int availablePoints,
  }) {
    if (_confirming case final premio?) {
      return ModernistRedeemSheet(
        premio: premio,
        balanceAfter: availablePoints - premio.costoPuntos,
        sending: _sending,
        onConfirm: () {
          if (_sending) return;
          unawaited(_submit(premio, operadorId));
        },
        onClose: dismissRedeem,
      );
    }

    if (_done case final premio?) {
      return ModernistRedeemSheet(
        premio: premio,
        balanceAfter: availablePoints,
        registered: true,
        onConfirm: dismissRedeem,
        onClose: dismissRedeem,
      );
    }

    if (_failed case final premio?) {
      return ModernistRedeemSheet(
        premio: premio,
        balanceAfter: availablePoints,
        error: _failure,
        onConfirm: dismissRedeem,
        onClose: dismissRedeem,
      );
    }

    return null;
  }
}

/// Traduce el error a algo que el operador pueda leer.
///
/// `ServerError` ya trae el motivo que dio la Edge Function («Puntos
/// insuficientes», «Premio no encontrado o inactivo»…), y ese es el que más
/// sirve: dice qué pasó y si vale la pena reintentar.
@visibleForTesting
String redeemErrorMessage(AppError error) => switch (error) {
      ServerError(:final message?) => message,
      NetworkError() =>
        'No hay conexión con el servidor. Revisa tu red e intenta de nuevo.',
      _ => 'No se pudo registrar el canje. Intenta de nuevo en un momento.',
    };
