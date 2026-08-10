import 'package:flutter/material.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';

/// Hoja de confirmación de canje.
///
/// Los exports «Perfil Operador» y «Premios Ruta» la declaran idéntica, así
/// que vive aquí y las dos pantallas la comparten. Tiene tres caras: la de
/// confirmar, la de acuse cuando el canje quedó registrado y la de fallo con
/// el motivo que dio el servidor. El fallo se cuenta aquí y no en un
/// `SnackBar` porque el resto del sistema no usa chrome de Material, y porque
/// antes la pantalla de Premios cerraba la hoja sin decir nada.
class ModernistRedeemSheet extends StatelessWidget {
  const ModernistRedeemSheet({
    required this.premio,
    required this.balanceAfter,
    required this.onConfirm,
    required this.onClose,
    this.registered = false,
    this.sending = false,
    this.error,
    super.key,
  });

  final Premio premio;

  /// Saldo que queda tras el canje; ya registrado o fallido, el saldo actual.
  final int balanceAfter;

  final VoidCallback onConfirm;
  final VoidCallback onClose;

  /// `true` cuando el canje ya se envió y la hoja pasa a ser un acuse.
  final bool registered;

  final bool sending;

  /// Motivo del rechazo. Con valor, la hoja pasa a ser un aviso de fallo.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final failed = error != null;

    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: palette.scrim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                // Absorbe el tap para que tocar la hoja no la cierre.
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.bg,
                    border: Border(
                      top: BorderSide(
                        color: palette.ink,
                        width: ModernistRule.base,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        failed
                            ? 'NO SE PUDO CANJEAR'
                            : registered
                                ? 'CANJE REGISTRADO'
                                : 'CONFIRMAR CANJE',
                        style: ModernistType.kicker(
                          size: 11,
                          tracking: 0.14,
                          color: failed ? ModernistColors.red : palette.kicker,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        premio.nombre,
                        style: ModernistType.of(
                          size: 24,
                          weight: 900,
                          color: palette.ink,
                          tracking: -0.02,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        error ??
                            (registered
                                ? 'Tu solicitud quedó registrada. Recursos '
                                    'Humanos te avisa en cuanto esté '
                                    'aprobada — lo verás aquí y en tus '
                                    'notificaciones.'
                                : 'Se descontarán '
                                    '${modernistNumber(premio.costoPuntos)} '
                                    'puntos de tu saldo disponible. El canje '
                                    'pasa a revisión de Recursos Humanos.'),
                        style: ModernistType.of(
                          size: 14,
                          weight: 500,
                          color: palette.bodyStrong,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: palette.ink,
                              width: ModernistRule.base,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                failed || registered
                                    ? 'SALDO DISPONIBLE'
                                    : 'SALDO DESPUÉS',
                                style: ModernistType.of(
                                  size: 12,
                                  weight: 700,
                                  color: palette.note,
                                  tracking: 0.1,
                                ),
                              ),
                            ),
                            Text(
                              '${modernistNumber(balanceAfter)} pts',
                              style: ModernistType.of(
                                size: 14,
                                weight: 800,
                                color: palette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Action(
                        label: sending
                            ? 'ENVIANDO…'
                            : failed
                                ? 'ENTENDIDO'
                                : registered
                                    ? 'LISTO'
                                    : 'SÍ, CANJEAR',
                        filled: true,
                        onTap: sending ? null : onConfirm,
                      ),
                      // Ya resuelto el canje no hay nada que cancelar.
                      if (!failed && !registered) ...[
                        const SizedBox(height: 10),
                        _Action(label: 'CANCELAR', onTap: onClose),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: filled ? ModernistColors.red : null,
          border: filled
              ? null
              : Border.all(color: palette.ink, width: ModernistRule.base),
        ),
        child: Text(
          label,
          style: ModernistType.of(
            size: 13,
            weight: 800,
            color: filled ? ModernistColors.onRed : palette.ink,
            tracking: 0.12,
          ),
        ),
      ),
    );
  }
}
