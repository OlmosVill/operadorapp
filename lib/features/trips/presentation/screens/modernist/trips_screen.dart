import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/points/domain/entities/point_movement.dart';
import 'package:operadorapp/features/points/presentation/providers/points_provider.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/modernist_tab_bar.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

/// Historial de viajes, implementando el export «Viajes».
///
/// Sustituye a `TripsListScreen`. La lista va agrupada por mes y cada viaje
/// abre una hoja con sus cifras y el desglose de puntos.
class ModernistTripsScreen extends ConsumerStatefulWidget {
  const ModernistTripsScreen({super.key});

  @override
  ConsumerState<ModernistTripsScreen> createState() =>
      _ModernistTripsScreenState();
}

class _ModernistTripsScreenState extends ConsumerState<ModernistTripsScreen> {
  Trip? _sheetTrip;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final tripsAsync = ref.watch(tripsProvider);
    final movements = ref.watch(movementsProvider).value ?? const [];
    final overlay =
        palette.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: palette.bg,
        systemNavigationBarIconBrightness:
            palette.isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.bg,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const _TripsHeader(),
                  _SummaryRow(trips: tripsAsync.value ?? const []),
                  Expanded(
                    child: tripsAsync.when(
                      loading: () =>
                          const AppLoadingWidget(message: 'Cargando...'),
                      error: (_, __) => const _TripsEmpty(),
                      data: (trips) => trips.isEmpty
                          ? const _TripsEmpty()
                          : _TripsList(
                              trips: trips,
                              onTap: (t) => setState(() => _sheetTrip = t),
                            ),
                    ),
                  ),
                  const ModernistTabBar(
                    current: ModernistTab.viajes,
                    ruled: true,
                  ),
                ],
              ),
              if (_sheetTrip case final trip?)
                _TripSheet(
                  trip: trip,
                  breakdown: _breakdownFor(trip, movements),
                  onClose: () => setState(() => _sheetTrip = null),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<PointsBreakdownRow> _breakdownFor(
    Trip trip,
    List<PointMovement> movements,
  ) {
    final movement = movements.firstWhereOrNull(
      (m) => m.viajeId == trip.id && m.tipo == MovementType.ganadoViaje,
    );
    return parsePointsBreakdown(movement?.descripcion);
  }
}

// ─── Desglose de puntos ─────────────────────────────────────────────────────

/// Una línea del desglose de puntos de un viaje. Es pública solo porque
/// [parsePointsBreakdown] se prueba por separado.
class PointsBreakdownRow {
  const PointsBreakdownRow(this.label, this.points);

  final String label;
  final int points;
}

/// `reglas_puntaje.variable` → etiqueta legible.
const _ruleLabels = <String, String>{
  'rendimiento': 'Rendimiento vs. esperado',
  'puntualidad': 'Puntualidad',
  'sin_reportes_mantenimiento': 'Sin reportes de mantenimiento',
  'alertas_seguridad': 'Alertas de seguridad',
  'incidencias': 'Incidencias',
};

/// Rescata el desglose por regla del texto de `movimientos_puntos.descripcion`.
///
/// **No hay una columna con el desglose**: la Edge Function
/// `calcular-puntos-viaje` lo serializa en la descripción como
/// `«Viaje completado. rendimiento: +113, puntualidad: +50, …»`.
///
/// Ojo que el trigger `fn_calcular_puntos_viaje` —que es el que corre de verdad
/// al cerrar un viaje— escribe otro formato **sin** desglose
/// (`«Viaje completado — 486 km, calif 4.8, 1 alertas, 0 incidencias»`), así
/// que para esos viajes esto devuelve vacío y la hoja muestra la nota. Ver
/// pendientes en `docs/features/modernist-home.md`.
@visibleForTesting
List<PointsBreakdownRow> parsePointsBreakdown(String? description) {
  if (description == null) return const [];

  final matches = RegExp(r'([a-z_]+)\s*:\s*([+-]?\d+)').allMatches(description);
  return [
    for (final m in matches)
      if (_ruleLabels[m.group(1)] case final label?)
        PointsBreakdownRow(label, int.parse(m.group(2)!)),
  ];
}

// ─── Estado del viaje ───────────────────────────────────────────────────────

/// Colores de la fila según el estado. Van aquí y no en [ModernistPalette]
/// porque solo tienen sentido junto a un `TripStatus`.
({Color label, Color mark}) _statusColors(
  TripStatus status,
  ModernistPalette palette,
) =>
    switch (status) {
      TripStatus.enCurso => (label: palette.danger, mark: ModernistColors.red),
      TripStatus.incidente => (label: palette.danger, mark: palette.disabled),
      TripStatus.cancelado => (label: palette.disabled, mark: palette.note),
      _ => (label: palette.note, mark: palette.ink),
    };

// ─── Cabecera y resumen ─────────────────────────────────────────────────────

class _TripsHeader extends StatelessWidget {
  const _TripsHeader();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      // Sin ancho explícito el contenedor se encoge al texto y la Column padre
      // lo centra: antes lo estiraba el Expanded del chip de tractos.
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTORIAL DE RUTAS',
            style: ModernistType.kicker(
              size: 11,
              tracking: 0.14,
              color: palette.kicker,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Mis viajes',
            style: ModernistType.of(
              size: 25,
              weight: 800,
              color: palette.ink,
              tracking: -0.02,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.trips});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final closed =
        trips.where((t) => t.estado == TripStatus.completado).toList();
    final km = closed.fold<double>(0, (s, t) => s + (t.kmRecorridos ?? 0));
    final points = closed.fold<int>(0, (s, t) => s + t.puntosObtenidos);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCell(
              label: 'COMPLETADOS',
              value: '${closed.length}',
              divider: true,
            ),
            _SummaryCell(
              label: 'KM',
              value: modernistNumber(km),
              divider: true,
            ),
            _SummaryCell(
              label: 'PUNTOS',
              value: '+${modernistNumber(points)}',
              valueColor: palette.positive,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.divider = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: divider
              ? Border(
                  right: BorderSide(
                    color: palette.ink,
                    width: ModernistRule.base,
                  ),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: ModernistType.kicker(
                size: 10,
                tracking: 0.12,
                color: palette.kicker,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: ModernistType.figure(
                size: 22,
                color: valueColor ?? palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lista ──────────────────────────────────────────────────────────────────

class _TripsList extends StatelessWidget {
  const _TripsList({required this.trips, required this.onTap});

  final List<Trip> trips;
  final void Function(Trip) onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final sorted = [...trips]..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));

    final children = <Widget>[];
    String? currentMonth;
    for (final trip in sorted) {
      final month = DateFormat('MMMM yyyy', 'es_MX').format(_dateOf(trip));
      if (month != currentMonth) {
        currentMonth = month;
        children.add(_MonthHeader(label: month.toUpperCase()));
      }
      children.add(_TripRow(trip: trip, onTap: () => onTap(trip)));
    }

    children.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Text(
          'Los puntos se acreditan al marcar el viaje como completado. '
          'Mínimo 10 puntos por viaje cerrado.',
          style: ModernistType.of(
            size: 12,
            weight: 600,
            color: palette.kicker,
          ),
        ),
      ),
    );

    return ListView(children: children);
  }

  static DateTime _dateOf(Trip trip) => trip.fechaInicio ?? trip.createdAt;
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            label,
            style: ModernistType.of(
              size: 12,
              weight: 900,
              color: palette.ink,
              tracking: 0.16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 2, color: palette.ink)),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final colors = _statusColors(trip.estado, palette);
    final active = trip.estado == TripStatus.enCurso;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: active ? palette.activeRowBg : null,
          border: Border(
            bottom: BorderSide(color: palette.rowDivider),
            left: BorderSide(color: colors.mark, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (active) ...[
                  const _PulsingDot(),
                  const SizedBox(width: 8),
                ],
                Text(
                  DateFormat('dd MMM yyyy', 'es_MX').format(
                    trip.fechaInicio ?? trip.createdAt,
                  ),
                  style: modernistMono(size: 10, color: palette.kicker),
                ),
                const Spacer(),
                Text(
                  trip.estado.displayName.toUpperCase(),
                  style: ModernistType.of(
                    size: 11,
                    weight: 800,
                    color: colors.label,
                    tracking: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    '${trip.origen} → ${trip.destino}',
                    style: ModernistType.of(
                      size: 16,
                      weight: 800,
                      color: palette.ink,
                      tracking: -0.01,
                      height: 1.2,
                    ),
                  ),
                ),
                if (trip.puntosObtenidos > 0) ...[
                  const SizedBox(width: 12),
                  Text(
                    '+${modernistNumber(trip.puntosObtenidos)}',
                    style: ModernistType.of(
                      size: 17,
                      weight: 900,
                      color: palette.positive,
                      tracking: -0.02,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 7),
            Text(
              _meta(trip),
              style: ModernistType.of(
                size: 11,
                weight: 600,
                color: palette.note,
                tracking: 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _meta(Trip trip) {
    final km = trip.kmRecorridos;
    if (km == null) return 'Sin recorrido registrado';
    final rend = trip.rendimientoReal;
    final suffix = rend == null ? '' : ' · ${rend.toStringAsFixed(1)} km/l';
    return '${modernistNumber(km)} km$suffix';
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeInOut);

    return SizedBox(
      width: 9,
      height: 9,
      child: AnimatedBuilder(
        animation: curve,
        builder: (context, _) => Transform.scale(
          scale: 0.7 + 0.65 * curve.value,
          child: Opacity(
            opacity: 1 - 0.45 * curve.value,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: ModernistColors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripsEmpty extends StatelessWidget {
  const _TripsEmpty();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Todavía no tienes viajes registrados. Aparecerán aquí en cuanto '
        'operación te asigne el primero.',
        style: ModernistType.of(
          size: 13,
          weight: 600,
          color: palette.kicker,
          height: 1.45,
        ),
      ),
    );
  }
}

// ─── Hoja de detalle ────────────────────────────────────────────────────────

class _TripSheet extends StatelessWidget {
  const _TripSheet({
    required this.trip,
    required this.breakdown,
    required this.onClose,
  });

  final Trip trip;
  final List<PointsBreakdownRow> breakdown;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: palette.scrim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.bg,
                    border: Border(
                      top: BorderSide(
                        color: palette.ink,
                        width: ModernistRule.base,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${DateFormat('dd MMM yyyy', 'es_MX').format(
                          trip.fechaInicio ?? trip.createdAt,
                        )} · ${trip.estado.displayName}'
                            .toUpperCase(),
                        style: ModernistType.kicker(
                          size: 11,
                          tracking: 0.14,
                          color: palette.kicker,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${trip.origen} → ${trip.destino}',
                        style: ModernistType.of(
                          size: 23,
                          weight: 900,
                          color: palette.ink,
                          tracking: -0.02,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _SheetStats(trip: trip),
                      if (breakdown.isNotEmpty)
                        _Breakdown(rows: breakdown, trip: trip)
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _noteFor(trip),
                            style: ModernistType.of(
                              size: 13,
                              weight: 500,
                              color: palette.bodyStrong,
                              height: 1.45,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SheetButton(
                              label: 'VER RUTA Y ALERTAS',
                              filled: true,
                              onTap: () =>
                                  unawaited(context.push('/trips/${trip.id}')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _SheetButton(label: 'CERRAR', onTap: onClose),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _noteFor(Trip trip) => switch (trip.estado) {
        TripStatus.enCurso =>
          'Los puntos se calculan al completar el viaje, con el rendimiento y '
              'las alertas del recorrido completo.',
        TripStatus.incidente =>
          'Viaje con incidencia abierta. Los puntos quedan en espera hasta '
              'que operación lo cierre.',
        TripStatus.cancelado =>
          'Viaje cancelado por operación. No genera puntos ni afecta tu '
              'rendimiento promedio.',
        // Completado o asignado sin desglose recuperable de la descripción.
        _ => 'Este viaje acreditó ${trip.puntosObtenidos} puntos. El desglose '
            'por regla no quedó registrado al cerrarlo.',
      };
}

class _SheetStats extends StatelessWidget {
  const _SheetStats({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final rule = BorderSide(color: palette.ink, width: ModernistRule.base);

    return Container(
      decoration: BoxDecoration(border: Border(top: rule, bottom: rule)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetStat(
              label: 'KM REC.',
              value: trip.kmRecorridos == null
                  ? '—'
                  : modernistNumber(trip.kmRecorridos!),
              padding: const EdgeInsets.fromLTRB(0, 11, 14, 11),
              divider: true,
            ),
            _SheetStat(
              label: 'REND. REAL',
              value: trip.rendimientoReal?.toStringAsFixed(1) ?? '—',
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              divider: true,
            ),
            _SheetStat(
              label: 'CALIF.',
              value: trip.calificacion?.toStringAsFixed(1) ?? '—',
              padding: const EdgeInsets.fromLTRB(14, 11, 0, 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetStat extends StatelessWidget {
  const _SheetStat({
    required this.label,
    required this.value,
    required this.padding,
    this.divider = false,
  });

  final String label;
  final String value;
  final EdgeInsets padding;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Expanded(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          border: divider
              ? Border(
                  right: BorderSide(
                    color: palette.ink,
                    width: ModernistRule.base,
                  ),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: ModernistType.kicker(
                size: 10,
                tracking: 0.12,
                color: palette.kicker,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: ModernistType.of(
                size: 20,
                weight: 900,
                color: palette.ink,
                tracking: -0.02,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.rows, required this.trip});

  final List<PointsBreakdownRow> rows;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESGLOSE DE PUNTOS',
            style: ModernistType.of(
              size: 11,
              weight: 800,
              color: palette.kicker,
              tracking: 0.12,
            ),
          ),
          const SizedBox(height: 6),
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.rowDivider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: ModernistType.of(
                        size: 13,
                        weight: 600,
                        color: palette.bodyStrong,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${row.points >= 0 ? '+' : ''}${row.points}',
                    style: ModernistType.of(
                      size: 13,
                      weight: 800,
                      color: switch (row.points) {
                        < 0 => palette.danger,
                        > 0 => palette.positive,
                        _ => palette.note,
                      },
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            color: palette.positiveSurface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    'TOTAL ACREDITADO',
                    style: ModernistType.of(
                      size: 12,
                      weight: 800,
                      color: palette.ink,
                      tracking: 0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '+${modernistNumber(trip.puntosObtenidos)}',
                  style: ModernistType.of(
                    size: 24,
                    weight: 900,
                    color: palette.positive,
                    tracking: -0.02,
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

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: filled ? ModernistColors.red : null,
          border: filled
              ? null
              : Border.all(color: palette.ink, width: ModernistRule.base),
        ),
        child: Text(
          label,
          style: ModernistType.of(
            size: 12,
            weight: 800,
            color: filled ? ModernistColors.onRed : palette.ink,
            tracking: 0.1,
          ),
        ),
      ),
    );
  }
}
