import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/trucks/domain/entities/truck.dart';
import 'package:operadorapp/features/trucks/presentation/providers/trucks_provider.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

class TruckDetailScreen extends ConsumerWidget {
  const TruckDetailScreen({required this.tractoId, super.key});

  final String tractoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(truckSummariesProvider).value;
    final summary = _findSummary(summaries, tractoId);
    final operadorId = ref.watch(profileProvider).value?.id ?? '';
    final reportsAsync = ref.watch(truckReportsProvider(tractoId));
    final rendimientoAsync = ref.watch(
      truckRendimientoProvider((tractoId, operadorId)),
    );

    if (summary == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const AppLoadingWidget(message: 'Cargando...'),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _Header(summary: summary),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (summary.marca != null) ...[
                  Text(
                    '${summary.marca}'
                    '${summary.modelo != null ? ' ${summary.modelo}' : ''}'
                    '${summary.anio != null ? ' · ${summary.anio}' : ''}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                _StatsRow(summary: summary),
                const SizedBox(height: 20),
                _RendimientoSection(
                  summary: summary,
                  rendimientoAsync: rendimientoAsync,
                ),
                const SizedBox(height: 20),
                _ReportesSection(reportsAsync: reportsAsync),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  TruckSummary? _findSummary(
    List<TruckSummary>? list,
    String id,
  ) {
    if (list == null) return null;
    for (final s in list) {
      if (s.tractoId == id) return s;
    }
    return null;
  }
}

// ─── Header SliverAppBar ─────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final TruckSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar.medium(
      title: Text(summary.numeroEconomico),
      actions: [
        if (summary.esActual)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: const Text('Tracto actual'),
              backgroundColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Stats row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});

  final TruckSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Km recorridos',
            value: summary.kmRecorridos.toStringAsFixed(0),
            icon: Icons.route_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Viajes',
            value: '${summary.viajesRealizados}',
            icon: Icons.local_shipping_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Calificación',
            value: summary.calificacionPromedio != null
                ? summary.calificacionPromedio!.toStringAsFixed(1)
                : '—',
            icon: Icons.star_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rendimiento section ─────────────────────────────────────────────────────

class _RendimientoSection extends StatelessWidget {
  const _RendimientoSection({
    required this.summary,
    required this.rendimientoAsync,
  });

  final TruckSummary summary;
  final AsyncValue<double?> rendimientoAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esperado = summary.rendimientoEsperado;
    final real = rendimientoAsync.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rendimiento de combustible',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (esperado != null) ...[
          _RendimientoBar(
            label: 'Esperado',
            valor: esperado,
            max: esperado,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 8),
        ],
        if (real != null && esperado != null) ...[
          _RendimientoBar(
            label: 'Real promedio',
            valor: real,
            max: esperado,
            color: real >= esperado
                ? Colors.green
                : theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            real >= esperado
                ? '✓ Por encima del esperado'
                : '✗ Por debajo del esperado',
            style: theme.textTheme.bodySmall?.copyWith(
              color: real >= esperado
                  ? Colors.green
                  : theme.colorScheme.error,
            ),
          ),
        ] else if (esperado == null && real == null) ...[
          Text(
            'Sin datos de rendimiento',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _RendimientoBar extends StatelessWidget {
  const _RendimientoBar({
    required this.label,
    required this.valor,
    required this.max,
    required this.color,
  });

  final String label;
  final double valor;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = max > 0 ? (valor / max).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${valor.toStringAsFixed(1)} km/l',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ─── Reportes section ────────────────────────────────────────────────────────

class _ReportesSection extends StatelessWidget {
  const _ReportesSection({required this.reportsAsync});

  final AsyncValue<List<TruckReport>> reportsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reportes',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        reportsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(
            'Error al cargar reportes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          data: (reports) {
            if (reports.isEmpty) {
              return Text(
                'Sin reportes registrados',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            final activos = reports
                .where((r) => r.estado != 'cerrado')
                .toList();
            final cerrados = reports
                .where((r) => r.estado == 'cerrado')
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activos.isNotEmpty) ...[
                  _ReporteGroup(
                    titulo: 'Activos',
                    reports: activos,
                    color: theme.colorScheme.error,
                  ),
                  if (cerrados.isNotEmpty)
                    const SizedBox(height: 12),
                ],
                if (cerrados.isNotEmpty)
                  _ReporteGroup(
                    titulo: 'Resueltos',
                    reports: cerrados,
                    color: Colors.green,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReporteGroup extends StatelessWidget {
  const _ReporteGroup({
    required this.titulo,
    required this.reports,
    required this.color,
  });

  final String titulo;
  final List<TruckReport> reports;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              titulo == 'Resueltos'
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_outlined,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$titulo (${reports.length})',
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...reports.map((r) => _ReporteTile(report: r, color: color)),
      ],
    );
  }
}

class _ReporteTile extends StatelessWidget {
  const _ReporteTile({required this.report, required this.color});

  final TruckReport report;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.descripcion,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  report.tipo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
