import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';

class MovementTile extends StatelessWidget {
  const MovementTile({required this.movement, super.key});

  final PointMovement movement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = movement.tipo.isCredit;
    final sign = isCredit ? '+' : '';
    final color = isCredit ? AppColors.amber : theme.colorScheme.error;
    final dateStr =
        DateFormat('dd MMM yyyy', 'es_MX').format(movement.createdAt.toLocal());

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withAlpha(30),
        child: Icon(_iconFor(movement.tipo), color: color, size: 20),
      ),
      title: Text(
        movement.descripcion ?? movement.tipo.displayName,
        style: theme.textTheme.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        dateStr,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withAlpha(120),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$sign${movement.puntos} pts',
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'saldo: ${movement.saldoDespues}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(MovementType tipo) => switch (tipo) {
        MovementType.ganadoViaje => Icons.route_rounded,
        MovementType.canjeado => Icons.card_giftcard_rounded,
        MovementType.ajusteManual => Icons.tune_rounded,
        MovementType.bonificacion => Icons.star_rounded,
        MovementType.penalizacion => Icons.warning_amber_rounded,
      };
}
