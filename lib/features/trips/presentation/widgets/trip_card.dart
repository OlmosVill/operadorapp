import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    required this.trip,
    required this.onTap,
    super.key,
  });

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = trip.fechaInicio ?? trip.createdAt;
    final dateLabel = DateFormat('dd MMM yyyy', 'es_MX').format(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _RouteRow(
                      origen: trip.origen,
                      destino: trip.destino,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: trip.estado),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                  if (trip.kmRecorridos != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.route_outlined,
                      size: 13,
                      color: theme.colorScheme.onSurface.withAlpha(120),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.kmRecorridos!.toStringAsFixed(0)} km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (trip.puntosObtenidos > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: AppColors.amber,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '+${trip.puntosObtenidos}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.origen, required this.destino});

  final String origen;
  final String destino;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    return Row(
      children: [
        Flexible(
          child: Text(
            origen,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, size: 14),
        ),
        Flexible(
          child: Text(
            destino,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
