import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';

class CanjeSheet extends ConsumerStatefulWidget {
  const CanjeSheet({required this.premio, super.key});

  final Premio premio;

  @override
  ConsumerState<CanjeSheet> createState() => _CanjeSheetState();
}

class _CanjeSheetState extends ConsumerState<CanjeSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final available = profile?.availablePoints ?? 0;
    final canAfford = available >= widget.premio.costoPuntos;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondaryDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Confirmar Canje',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _PremioSummary(premio: widget.premio),
          const SizedBox(height: 20),
          _PointsRow(
            label: 'Puntos disponibles',
            value: available,
            color: canAfford ? Colors.green : AppColors.textSecondaryDark,
          ),
          _PointsRow(
            label: 'Costo del canje',
            value: widget.premio.costoPuntos,
            color: AppColors.amber,
          ),
          if (canAfford)
            _PointsRow(
              label: 'Saldo tras el canje',
              value: available - widget.premio.costoPuntos,
              color: AppColors.textSecondaryDark,
            ),
          const SizedBox(height: 8),
          if (!canAfford)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No tienes puntos suficientes para este premio.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: canAfford && !_loading ? _onConfirm : null,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirmar canje'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _onConfirm() async {
    final operadorId = ref.read(profileProvider).value?.id;
    if (operadorId == null) return;

    setState(() => _loading = true);

    final result = await ref.read(canjearUsecaseProvider).call(
          premioId: widget.premio.id,
          operadorId: operadorId,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    result.fold(
      (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err.toString().contains('Puntos insuficientes')
                  ? 'Puntos insuficientes para este canje'
                  : 'Error al solicitar el canje. Intenta de nuevo.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Canje solicitado! RH lo revisará pronto.'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }
}

// ─── Subwidgets ──────────────────────────────────────────────────────────────

class _PremioSummary extends StatelessWidget {
  const _PremioSummary({required this.premio});

  final Premio premio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.concreteCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.redeem_rounded, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                premio.nombre,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (premio.descripcion != null) ...[
                const SizedBox(height: 4),
                Text(
                  premio.descripcion!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                premio.tipo.displayName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.amber,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PointsRow extends StatelessWidget {
  const _PointsRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              Icon(Icons.stars_rounded, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '$value pts',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
