import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/features/trucks/domain/entities/truck.dart';
import 'package:operadorapp/features/trucks/presentation/providers/trucks_provider.dart';
import 'package:operadorapp/shared/widgets/app_error_widget.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

class TrucksHistoryScreen extends ConsumerWidget {
  const TrucksHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(truckSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Tractos')),
      body: summariesAsync.when(
        loading: () =>
            const AppLoadingWidget(message: 'Cargando tractos...'),
        error: (error, _) => AppErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(truckSummariesProvider),
        ),
        data: (summaries) => summaries.isEmpty
            ? const _EmptyTrucks()
            : ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: summaries.length,
                itemBuilder: (_, i) => _TruckCard(
                  summary: summaries[i],
                )
                    .animate()
                    .fadeIn(
                      duration: 300.ms,
                      delay: Duration(milliseconds: 50 * i),
                    )
                    .slideY(begin: 0.04, end: 0),
              ),
      ),
    );
  }
}

// ─── Truck card ──────────────────────────────────────────────────────────────

class _TruckCard extends StatelessWidget {
  const _TruckCard({required this.summary});

  final TruckSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = _label(summary);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/trucks/${summary.tractoId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _TruckIcon(esActual: summary.esActual),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            summary.numeroEconomico,
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (summary.esActual)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Actual',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (label != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Stat(
                          icon: Icons.route_outlined,
                          value:
                              '${summary.kmRecorridos.toStringAsFixed(0)} km',
                        ),
                        const SizedBox(width: 16),
                        _Stat(
                          icon: Icons.local_shipping_outlined,
                          value: '${summary.viajesRealizados} viajes',
                        ),
                        if (summary.calificacionPromedio != null) ...[
                          const SizedBox(width: 16),
                          _Stat(
                            icon: Icons.star_outline_rounded,
                            value: summary.calificacionPromedio!
                                .toStringAsFixed(1),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String? _label(TruckSummary s) {
    final parts = <String>[];
    if (s.marca != null) parts.add(s.marca!);
    if (s.modelo != null) parts.add(s.modelo!);
    if (s.anio != null) parts.add('${s.anio}');
    return parts.isEmpty ? null : parts.join(' ');
  }
}

class _TruckIcon extends StatelessWidget {
  const _TruckIcon({required this.esActual});

  final bool esActual;

  @override
  Widget build(BuildContext context) {
    final color = esActual
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.local_shipping_outlined, color: color),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(value, style: style),
      ],
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyTrucks extends StatelessWidget {
  const _EmptyTrucks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin historial de tractos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
