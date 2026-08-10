import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/profile/domain/entities/level_thresholds.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/summary/domain/entities/return_summary.dart';

/// Popup de «esto pasó mientras no estabas», implementando el export
/// «Resumen Regreso».
Future<void> showReturnSummaryDialog(
  BuildContext context,
  ReturnSummary summary,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    // rgba(23,22,21,.72) del export.
    barrierColor: const Color(0xB8171615),
    builder: (_) => ModernistReturnSummaryDialog(summary: summary),
  );
}

class ModernistReturnSummaryDialog extends StatefulWidget {
  const ModernistReturnSummaryDialog({required this.summary, super.key});

  final ReturnSummary summary;

  @override
  State<ModernistReturnSummaryDialog> createState() =>
      _ModernistReturnSummaryDialogState();
}

class _ModernistReturnSummaryDialogState
    extends State<ModernistReturnSummaryDialog> {
  /// Fase 1 llena la barra del nivel viejo hasta el tope; la 2 arranca de cero
  /// en el nuevo. Con una sola animación el progreso parecería retroceder.
  int _phase = 0;
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _play();
  }

  void _play() {
    setState(() {
      _phase = 0;
      _run++;
    });

    final leveledUp = widget.summary.leveledUp;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _phase = leveledUp ? 1 : 2);
    });

    if (leveledUp) {
      Future<void>.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) setState(() => _phase = 2);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final summary = widget.summary;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: palette.bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.ink, width: ModernistRule.base),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(summary: summary),
              _PointsBlock(
                key: ValueKey('points-$_run'),
                points: summary.pointsEarned,
                leveledUp: summary.leveledUp,
                level: summary.levelAfter,
              ),
              _LevelBlock(summary: summary, phase: _phase),
              if (summary.rankDelta case final delta?
                  when delta != 0 || summary.rankAfter != null)
                _RankBlock(summary: summary, delta: delta),
              if (summary.completedTrips.isNotEmpty)
                _TripsBlock(summary: summary),
              _Actions(
                onContinue: () => Navigator.of(context).pop(),
                onReplay: _play,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cabecera ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final ReturnSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MIENTRAS NO ESTABAS',
            style: ModernistType.of(
              size: 10,
              weight: 800,
              color: palette.kicker,
              tracking: 0.16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _title(summary),
            style: ModernistType.of(
              size: 26,
              weight: 900,
              color: palette.ink,
              tracking: -0.03,
              height: 1.03,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Desde el ${DateFormat("d 'de' MMMM · HH:mm", 'es_MX').format(
              summary.since,
            )}',
            style: ModernistType.of(
              size: 12,
              weight: 600,
              color: palette.note,
            ),
          ),
        ],
      ),
    );
  }

  static String _title(ReturnSummary summary) {
    if (summary.leveledUp) {
      return 'Subiste a ${summary.levelAfter.displayName}';
    }
    final trips = summary.completedTrips.length;
    if (trips > 0) {
      return trips == 1
          ? 'Se cerró tu viaje'
          : 'Se cerraron $trips viajes';
    }
    return 'Tienes movimientos nuevos';
  }
}

// ─── Puntos ─────────────────────────────────────────────────────────────────

class _PointsBlock extends StatelessWidget {
  const _PointsBlock({
    required this.points,
    required this.leveledUp,
    required this.level,
    super.key,
  });

  final int points;
  final bool leveledUp;
  final OperatorLevel level;

  @override
  Widget build(BuildContext context) {
    const white = ModernistColors.onRed;

    return Container(
      color: ModernistColors.red,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                // El contador sube desde cero, como en el export.
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: points),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Text(
                    modernistNumber(value),
                    style: ModernistType.of(
                      size: 52,
                      weight: 900,
                      color: white,
                      tracking: -0.04,
                      height: 0.92,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Opacity(
                  opacity: 0.9,
                  child: Text(
                    'PTS',
                    style: ModernistType.of(
                      size: 16,
                      weight: 800,
                      color: white,
                      tracking: 0.06,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Opacity(
                opacity: 0.9,
                child: Text(
                  leveledUp
                      ? 'TE ALCANZÓ PARA ${level.displayName.toUpperCase()}'
                      : 'ACREDITADOS A TU SALDO',
                  textAlign: TextAlign.right,
                  style: ModernistType.of(
                    size: 11,
                    weight: 700,
                    color: white,
                    tracking: 0.1,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nivel ──────────────────────────────────────────────────────────────────

class _LevelBlock extends StatelessWidget {
  const _LevelBlock({required this.summary, required this.phase});

  final ReturnSummary summary;

  /// 0 = en reposo · 1 = llenando el nivel viejo · 2 = ya en el nuevo.
  final int phase;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    // Con ascenso de nivel la barra corre en dos tramos; sin él, uno solo.
    final showingNew = phase == 2;
    final level = showingNew ? summary.levelAfter : summary.levelBefore;
    final value = switch (phase) {
      0 => summary.progressBefore,
      1 => 1.0,
      _ => summary.progressAfter,
    };

    final floor = levelFloor(level);
    final ceiling = nextLevelPoints(level);
    final missing = summary.pointsToNextLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'NIVEL',
                  style: ModernistType.of(
                    size: 11,
                    weight: 800,
                    color: palette.kicker,
                    tracking: 0.12,
                  ),
                ),
              ),
              Text(
                level.displayName.toUpperCase(),
                style: ModernistType.of(
                  size: 11,
                  weight: 800,
                  // Se enciende al llegar al nivel nuevo.
                  color: showingNew && summary.leveledUp
                      ? palette.danger
                      : palette.note,
                  tracking: 0.08,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LevelChip(color: ModernistColors.level(level)),
              const SizedBox(width: 10),
              Expanded(child: _LevelBar(value: value, phase: phase)),
              const SizedBox(width: 10),
              _LevelChip(
                color: level.next == null
                    ? null
                    : ModernistColors.level(level.next!),
                dashed: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${modernistNumber(floor)} PTS',
                  style: _scaleStyle(palette),
                ),
              ),
              Text(
                ceiling == null ? 'MÁX' : '${modernistNumber(ceiling)} PTS',
                style: _scaleStyle(palette),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            missing == null
                ? 'Llegaste al nivel más alto de la flota.'
                : 'Te faltan ${modernistNumber(missing)} pts para '
                    '${level.next?.displayName ?? ''}.',
            style: ModernistType.of(
              size: 13,
              weight: 700,
              color: palette.ink,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle _scaleStyle(ModernistPalette palette) => ModernistType.of(
        size: 11,
        weight: 800,
        color: palette.note,
        tracking: 0.04,
      );
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({this.color, this.dashed = false});

  final Color? color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Opacity(
      opacity: color == null ? 0.35 : 1,
      child: CustomPaint(
        // El recuadro del siguiente nivel va punteado: todavía no se alcanza.
        foregroundPainter: dashed
            ? _DashedBorderPainter(color: palette.kicker)
            : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            border: dashed
                ? null
                : Border.all(color: palette.ink, width: ModernistRule.base),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const dash = 4.0;
    const gap = 3.0;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final path = Path()..addRect(rect);

    for (final metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        final end = (at + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(at, end), paint);
        at = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.value, required this.phase});

  final double value;
  final int phase;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: palette.progressTrack,
        border: Border.all(color: palette.ink, width: ModernistRule.base),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            // El salto de la fase 1 a la 2 es un corte, no una transición:
            // la barra vuelve a cero en el nivel nuevo.
            duration: phase == 2
                ? const Duration(milliseconds: 900)
                : const Duration(milliseconds: 1000),
            curve: const Cubic(0.25, 0.85, 0.3, 1),
            width: constraints.maxWidth * value.clamp(0.0, 1.0),
            color: ModernistColors.red,
          ),
        ),
      ),
    );
  }
}

// ─── Ranking ────────────────────────────────────────────────────────────────

class _RankBlock extends StatelessWidget {
  const _RankBlock({required this.summary, required this.delta});

  final ReturnSummary summary;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final up = delta > 0;
    final tint = delta == 0
        ? palette.note
        : up
            ? palette.rankUp
            : palette.rankDown;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Row(
        children: [
          Text(
            delta == 0 ? '—' : '${up ? '+' : ''}$delta',
            style: ModernistType.of(
              size: 13,
              weight: 800,
              color: tint,
              tracking: 0.04,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  switch (delta) {
                    > 0 => 'Subiste ${delta.abs()} '
                        '${delta.abs() == 1 ? 'lugar' : 'lugares'}',
                    < 0 => 'Bajaste ${delta.abs()} '
                        '${delta.abs() == 1 ? 'lugar' : 'lugares'}',
                    _ => 'Mantuviste tu lugar',
                  },
                  style: ModernistType.of(
                    size: 14,
                    weight: 800,
                    color: palette.ink,
                    tracking: -0.01,
                  ),
                ),
                if (summary.rankAfter case final position?)
                  Text(
                    'Ahora vas en el lugar $position',
                    style: ModernistType.of(
                      size: 12,
                      weight: 600,
                      color: palette.note,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              unawaited(context.push('/ranking'));
            },
            child: Text(
              'VER TABLA',
              style: ModernistType.of(
                size: 11,
                weight: 800,
                color: palette.link,
                tracking: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Viajes ─────────────────────────────────────────────────────────────────

class _TripsBlock extends StatelessWidget {
  const _TripsBlock({required this.summary});

  final ReturnSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final trips = summary.completedTrips;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  trips.length == 1
                      ? 'VIAJE CERRADO'
                      : '${trips.length} VIAJES CERRADOS',
                  style: ModernistType.of(
                    size: 11,
                    weight: 800,
                    color: palette.kicker,
                    tracking: 0.12,
                  ),
                ),
              ),
              Text(
                '${modernistNumber(summary.totalKm)} KM',
                style: ModernistType.of(
                  size: 11,
                  weight: 800,
                  color: palette.note,
                  tracking: 0.04,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final trip in trips)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: palette.rowDivider.withValues(alpha: 0.28),
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      '${trip.origen} → ${trip.destino}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ModernistType.of(
                        size: 13,
                        weight: 600,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '+${modernistNumber(trip.puntosObtenidos)}',
                    style: ModernistType.of(
                      size: 13,
                      weight: 800,
                      color: palette.rankUp,
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

// ─── Acciones ───────────────────────────────────────────────────────────────

class _Actions extends StatelessWidget {
  const _Actions({required this.onContinue, required this.onReplay});

  final VoidCallback onContinue;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onContinue,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerLeft,
              color: ModernistColors.red,
              child: Text(
                'CONTINUAR',
                style: ModernistType.of(
                  size: 13,
                  weight: 800,
                  color: ModernistColors.onRed,
                  tracking: 0.12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onReplay,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border.all(
                  color: palette.ink,
                  width: ModernistRule.base,
                ),
              ),
              child: Text(
                'REPETIR ANIMACIÓN',
                style: ModernistType.of(
                  size: 12,
                  weight: 800,
                  color: palette.ink,
                  tracking: 0.12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
