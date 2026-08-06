import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/widgets/level_badge.dart';
import 'package:operadorapp/features/ranking/presentation/widgets/rank_change_indicator.dart';
import 'package:operadorapp/features/summary/domain/entities/return_summary.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';

/// Popup de "esto pasó mientras no estabas".
Future<void> showReturnSummaryDialog(
  BuildContext context,
  ReturnSummary summary,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withAlpha(180),
    builder: (_) => ReturnSummaryDialog(summary: summary),
  );
}

class ReturnSummaryDialog extends StatelessWidget {
  const ReturnSummaryDialog({required this.summary, super.key});

  final ReturnSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(summary: summary),
                const SizedBox(height: 20),
                _PointsBurst(pointsEarned: summary.pointsEarned)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .scale(begin: const Offset(0.85, 0.85)),
                const SizedBox(height: 24),
                _LevelSection(summary: summary)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms)
                    .slideY(begin: 0.15, end: 0),
                if (summary.rankDelta != null) ...[
                  const SizedBox(height: 16),
                  _RankSection(summary: summary)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 900.ms)
                      .slideY(begin: 0.15, end: 0),
                ],
                if (summary.completedTrips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _TripsSection(summary: summary)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 1100.ms)
                      .slideY(begin: 0.15, end: 0),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Continuar'),
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 1400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final ReturnSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          summary.leveledUp
              ? Icons.workspace_premium_rounded
              : Icons.waving_hand_rounded,
          size: 40,
          color: AppColors.amber,
        )
            .animate()
            .scale(duration: 500.ms, curve: Curves.elasticOut)
            .then()
            .shimmer(duration: 900.ms, color: Colors.white54),
        const SizedBox(height: 10),
        Text(
          summary.leveledUp ? '¡Subiste de nivel!' : '¡Bienvenido de vuelta!',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Esto pasó ${_desde(summary.since)}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _desde(DateTime since) {
    final dias = DateTime.now().difference(since).inDays;
    if (dias <= 0) return 'desde tu última visita';
    if (dias == 1) return 'desde ayer';
    if (dias < 30) return 'en los últimos $dias días';
    final meses = (dias / 30).floor();
    return meses == 1 ? 'en el último mes' : 'en los últimos $meses meses';
  }
}

// ─── Puntos ganados ──────────────────────────────────────────────────────────

class _PointsBurst extends StatelessWidget {
  const _PointsBurst({required this.pointsEarned});

  final int pointsEarned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positivo = pointsEarned >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A2800), Color(0xFF2A1800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            positivo ? 'Ganaste' : 'Movimiento de puntos',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.amber.withAlpha(180),
            ),
          ),
          const SizedBox(height: 4),
          // El contador sube desde cero: es la parte que hace sentir el premio.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pointsEarned.toDouble()),
            duration: 1200.ms,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${positivo ? '+' : ''}${value.round()}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'pts',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.amber.withAlpha(200),
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

// ─── Nivel y barra de progreso ───────────────────────────────────────────────

class _LevelSection extends StatelessWidget {
  const _LevelSection({required this.summary});

  final ReturnSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siguiente = summary.levelAfter.next;
    final faltan = summary.pointsToNextLevel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LevelBadge(level: summary.levelAfter, size: 34),
              const Spacer(),
              if (siguiente != null)
                Opacity(
                  opacity: 0.55,
                  child: LevelBadge(level: siguiente, size: 26),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _AnimatedLevelBar(summary: summary),
          const SizedBox(height: 8),
          Text(
            faltan == null
                ? 'Nivel máximo alcanzado'
                : 'Te faltan $faltan pts para ${siguiente?.displayName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra que se llena sola desde el progreso anterior.
///
/// Si hubo cambio de nivel corre en dos tiempos: primero llena la barra del
/// nivel viejo hasta el tope y luego reinicia en cero con el nivel nuevo. Una
/// sola animación se vería como si el progreso hubiera retrocedido.
class _AnimatedLevelBar extends StatefulWidget {
  const _AnimatedLevelBar({required this.summary});

  final ReturnSummary summary;

  @override
  State<_AnimatedLevelBar> createState() => _AnimatedLevelBarState();
}

class _AnimatedLevelBarState extends State<_AnimatedLevelBar> {
  late double _desde;
  late double _hasta;
  late OperatorLevel _nivel;
  var _segundaFase = false;

  @override
  void initState() {
    super.initState();
    final s = widget.summary;

    if (s.leveledUp) {
      _desde = s.progressBefore;
      _hasta = 1;
      _nivel = s.levelBefore;
    } else {
      _desde = s.progressBefore;
      _hasta = s.progressAfter;
      _nivel = s.levelAfter;
    }
  }

  void _alTerminar() {
    if (!widget.summary.leveledUp || _segundaFase || !mounted) return;
    setState(() {
      _segundaFase = true;
      _desde = 0;
      _hasta = widget.summary.progressAfter;
      _nivel = widget.summary.levelAfter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = levelColor(_nivel);

    return TweenAnimationBuilder<double>(
      // La key fuerza a reconstruir el tween en la segunda fase para que
      // arranque desde `begin` en vez de interpolar desde el valor actual.
      key: ValueKey(_segundaFase),
      tween: Tween(begin: _desde, end: _hasta),
      duration: _segundaFase ? 900.ms : 1100.ms,
      curve: Curves.easeOutCubic,
      onEnd: _alTerminar,
      builder: (context, value, _) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 10,
          backgroundColor:
              Theme.of(context).colorScheme.onSurface.withAlpha(20),
          color: color,
        ),
      ),
    );
  }
}

// ─── Lugares en el ranking ───────────────────────────────────────────────────

class _RankSection extends StatelessWidget {
  const _RankSection({required this.summary});

  final ReturnSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = summary.rankDelta ?? 0;

    final texto = switch (delta) {
      > 0 => 'Subiste $delta ${delta == 1 ? 'lugar' : 'lugares'}',
      < 0 => 'Bajaste ${-delta} ${delta == -1 ? 'lugar' : 'lugares'}',
      _ => 'Mantuviste tu lugar',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.leaderboard_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ahora vas en el lugar #${summary.rankAfter}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          RankChangeIndicator(delta: summary.rankDelta),
        ],
      ),
    );
  }
}

// ─── Viajes completados ──────────────────────────────────────────────────────

class _TripsSection extends StatelessWidget {
  const _TripsSection({required this.summary});

  final ReturnSummary summary;

  static const _maxVisibles = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trips = summary.completedTrips;
    final visibles = trips.take(_maxVisibles).toList();
    final restantes = trips.length - visibles.length;
    final titulo = trips.length == 1
        ? '1 viaje completado'
        : '${trips.length} viajes completados';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 18),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${summary.totalKm.toStringAsFixed(0)} km',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < visibles.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _TripRow(trip: visibles[i])
                  .animate()
                  .fadeIn(
                    duration: 300.ms,
                    delay: (1200 + i * 120).ms,
                  )
                  .slideX(begin: 0.06, end: 0),
            ),
          if (restantes > 0)
            Text(
              'y $restantes más',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            '${trip.origen} → ${trip.destino}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '+${trip.puntosObtenidos}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
