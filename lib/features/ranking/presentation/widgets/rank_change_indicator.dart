import 'package:flutter/material.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';

/// Flecha ▲ / ▼ con el número de lugares movidos, o un guion si sigue en el
/// mismo lugar (o si aún no hay corte previo con qué comparar).
///
/// Toma el delta crudo para poder usarse tanto en la tabla de posiciones como
/// en el resumen de regreso, que no tiene un `RankingEntry` a la mano.
class RankChangeIndicator extends StatelessWidget {
  const RankChangeIndicator({
    required this.delta,
    super.key,
    this.compact = false,
  });

  /// Construye el indicador desde una fila del ranking.
  RankChangeIndicator.fromEntry(
    RankingEntry entry, {
    Key? key,
    bool compact = false,
  }) : this(delta: entry.lugaresMovidos, key: key, compact: compact);

  /// Lugares ganados (positivo) o perdidos (negativo). null = sin referencia.
  final int? delta;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, label) = _assets(theme);
    final iconSize = compact ? 14.0 : 16.0;

    return Semantics(
      label: _semanticsLabel(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(28),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: color),
            if (label != null) ...[
              const SizedBox(width: 2),
              Text(
                label,
                style: (compact
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, Color, String?) _assets(ThemeData theme) {
    final d = delta;
    if (d != null && d > 0) {
      return (Icons.arrow_drop_up_rounded, AppColors.success, '$d');
    }
    if (d != null && d < 0) {
      return (Icons.arrow_drop_down_rounded, AppColors.error, '${-d}');
    }
    return (
      Icons.remove_rounded,
      theme.colorScheme.onSurfaceVariant,
      null,
    );
  }

  String _semanticsLabel() {
    final d = delta;
    if (d == null) return 'Sin historial previo';
    if (d > 0) return 'Subió $d lugares';
    if (d < 0) return 'Bajó ${-d} lugares';
    return 'Sin cambio de lugar';
  }
}
