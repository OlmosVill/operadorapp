import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/canje_sheet.dart';

enum _PremioStatus { disponible, proximo, nivelInsuficiente }

class PremioCard extends ConsumerWidget {
  const PremioCard({required this.premio, super.key});

  final Premio premio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final status = _statusFor(premio, profile);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: status == _PremioStatus.disponible
            ? () => _openSheet(context, ref)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PremioImage(imagenUrl: premio.imagenUrl, tipo: premio.tipo),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      premio.nombre,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          size: 14,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${premio.costoPuntos} pts',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _StatusChip(status: status, premio: premio),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => CanjeSheet(premio: premio),
      ),
    );
  }

  static _PremioStatus _statusFor(
    Premio premio,
    OperatorProfile? profile,
  ) {
    if (profile == null) return _PremioStatus.proximo;
    if (premio.nivelMinimo != null &&
        profile.level.index < premio.nivelMinimo!.index) {
      return _PremioStatus.nivelInsuficiente;
    }
    return profile.availablePoints >= premio.costoPuntos
        ? _PremioStatus.disponible
        : _PremioStatus.proximo;
  }
}

// ─── Subwidgets ──────────────────────────────────────────────────────────────

class _PremioImage extends StatelessWidget {
  const _PremioImage({required this.imagenUrl, required this.tipo});

  final String? imagenUrl;
  final PremioTipo tipo;

  @override
  Widget build(BuildContext context) {
    if (imagenUrl != null) {
      return Image.network(
        imagenUrl!,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        height: 100,
        color: AppColors.concreteCard,
        child: Icon(
          _iconForTipo(tipo),
          size: 40,
          color: AppColors.textSecondaryDark,
        ),
      );

  IconData _iconForTipo(PremioTipo tipo) => switch (tipo) {
        PremioTipo.tarjetaRegalo => Icons.card_giftcard_rounded,
        PremioTipo.producto => Icons.inventory_2_rounded,
        PremioTipo.experiencia => Icons.event_rounded,
        PremioTipo.vehiculo => Icons.local_shipping_rounded,
        PremioTipo.otro => Icons.redeem_rounded,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.premio});

  final _PremioStatus status;
  final Premio premio;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _PremioStatus.disponible => ('Disponible', Colors.green),
      _PremioStatus.proximo => ('Próximo', AppColors.amber),
      _PremioStatus.nivelInsuficiente => (
          'Nivel ${premio.nivelMinimo?.displayName ?? ''}',
          AppColors.textSecondaryDark,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
