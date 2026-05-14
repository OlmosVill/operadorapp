import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/trips/domain/entities/security_alert.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_detail.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_incident.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trips/presentation/widgets/trip_map_view.dart';
import 'package:operadorapp/shared/widgets/app_error_widget.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tripDetailProvider(tripId));
    return detailAsync.when(
      loading: () => const Scaffold(
        body: AppLoadingWidget(message: 'Cargando viaje...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: AppErrorWidget(error: error),
      ),
      data: (detail) => _DetailView(detail: detail),
    );
  }
}

// ─── Detail layout ──────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  const _DetailView({required this.detail});

  final TripDetail detail;

  @override
  Widget build(BuildContext context) {
    final trip = detail.trip;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: _TripTitle(origen: trip.origen, destino: trip.destino),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList.list(
              children: [
                _StatusBar(trip: trip),
                const SizedBox(height: 20),
                _StatsGrid(trip: trip),
                if (detail.gpsPoints.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel(text: 'Ruta GPS'),
                  const SizedBox(height: 8),
                  TripMapView(points: detail.gpsPoints),
                ],
                if (detail.incidents.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel(text: 'Incidencias'),
                  const SizedBox(height: 4),
                  ...detail.incidents.map(
                    (i) => _IncidentTile(incident: i),
                  ),
                ],
                if (detail.securityAlerts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel(text: 'Alertas de seguridad'),
                  const SizedBox(height: 4),
                  ...detail.securityAlerts.map(
                    (a) => _AlertTile(alert: a),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable sub-widgets ───────────────────────────────────────────────────

class _TripTitle extends StatelessWidget {
  const _TripTitle({required this.origen, required this.destino});

  final String origen;
  final String destino;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          origen,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            const Icon(Icons.south, size: 11),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                destino,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd MMM yyyy · HH:mm', 'es_MX');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusChip(status: trip.estado),
            if (trip.calificacion != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 2),
              Text(
                trip.calificacion!.toStringAsFixed(1),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        if (trip.fechaInicio != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                fmt.format(trip.fechaInicio!),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
        if (trip.fechaFin != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 16, color: AppColors.amber),
              const SizedBox(width: 6),
              Text(
                fmt.format(trip.fechaFin!),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TripStatus status;

  Color _color() => switch (status) {
        TripStatus.enCurso => AppColors.info,
        TripStatus.completado => AppColors.success,
        TripStatus.cancelado => AppColors.error,
        TripStatus.incidente => AppColors.warning,
        TripStatus.asignado => AppColors.textSecondaryDark,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.7,
      children: [
        _StatCard(
          icon: Icons.route,
          label: 'KM recorridos',
          value: trip.kmRecorridos != null
              ? '${trip.kmRecorridos!.toStringAsFixed(1)} km'
              : '—',
        ),
        _StatCard(
          icon: Icons.speed,
          label: 'Rendimiento',
          value: trip.rendimientoReal != null
              ? '${trip.rendimientoReal!.toStringAsFixed(1)} km/l'
              : '—',
        ),
        _StatCard(
          icon: Icons.local_gas_station_outlined,
          label: 'Litros diesel',
          value: trip.litrosDiesel != null
              ? '${trip.litrosDiesel!.toStringAsFixed(1)} L'
              : '—',
        ),
        _StatCard(
          icon: Icons.stars_rounded,
          label: 'Puntos',
          value: '+${trip.puntosObtenidos}',
          highlighted: trip.puntosObtenidos > 0,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlighted ? AppColors.amber : theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlighted ? AppColors.amber : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.incident});

  final TripIncident incident;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM · HH:mm', 'es_MX');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 20,
        ),
      ),
      title: Text(
        incident.tipo,
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: incident.descripcion != null
          ? Text(
              incident.descripcion!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            fmt.format(incident.timestampIncidencia),
            style: theme.textTheme.bodySmall,
          ),
          if (incident.impactoPuntos != 0)
            Text(
              '${incident.impactoPuntos > 0 ? '+' : ''}'
              '${incident.impactoPuntos} pts',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final SecurityAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM · HH:mm', 'es_MX');
    final subtitle =
        (alert.valorMedido != null && alert.umbralPermitido != null)
            ? 'Medido: ${alert.valorMedido!.toStringAsFixed(1)} '
                '/ Límite: ${alert.umbralPermitido!.toStringAsFixed(1)}'
            : null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.shield_outlined,
          color: AppColors.error,
          size: 20,
        ),
      ),
      title: Text(
        alert.tipo,
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            fmt.format(alert.timestampAlerta),
            style: theme.textTheme.bodySmall,
          ),
          if (alert.impactoPuntos != 0)
            Text(
              '${alert.impactoPuntos} pts',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}
