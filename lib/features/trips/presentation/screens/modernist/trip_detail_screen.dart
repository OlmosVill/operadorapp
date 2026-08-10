import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/trips/domain/entities/security_alert.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_detail.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_incident.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/gps_route_illustration.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

/// Detalle de un viaje, implementando el export «Detalle Viaje».
///
/// Sustituye a la `TripDetailScreen` anterior. Es la pantalla que mejor calza
/// con el modelo que ya existía: todo lo que pide el export sale de
/// `TripDetail` sin inventar campos.
class ModernistTripDetailScreen extends ConsumerWidget {
  const ModernistTripDetailScreen({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ModernistPalette.of(context);
    final detailAsync = ref.watch(tripDetailProvider(tripId));
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
          child: detailAsync.when(
            loading: () => const AppLoadingWidget(message: 'Cargando viaje...'),
            // `AppErrorWidget` todavía pinta con el tema anterior, así que
            // aquí va un mensaje propio para no romper el sistema.
            error: (_, __) => const _DetailUnavailable(),
            data: (detail) => _DetailBody(detail: detail),
          ),
        ),
      ),
    );
  }
}

class _DetailUnavailable extends StatelessWidget {
  const _DetailUnavailable();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'No pudimos cargar este viaje. Vuelve a intentarlo cuando tengas '
        'conexión.',
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

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final TripDetail detail;

  @override
  Widget build(BuildContext context) {
    final trip = detail.trip;

    return Column(
      children: [
        _DetailHeader(trip: trip),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _StatusBlock(trip: trip),
              _StatsGrid(trip: trip),
              const _SectionTitle('RUTA GPS', padding: 15),
              _RouteBlock(detail: detail),
              _Legend(gpsCount: detail.gpsPoints.length),
              if (detail.incidents.isNotEmpty)
                _IncidentsSection(incidents: detail.incidents),
              if (detail.securityAlerts.isNotEmpty)
                _AlertsSection(alerts: detail.securityAlerts),
              const _FooterNote(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Cabecera ───────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/trips'),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: palette.ink,
                  width: ModernistRule.base,
                ),
              ),
              child: Text(
                '←',
                style: ModernistType.of(
                  size: 19,
                  weight: 900,
                  color: palette.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip.origen,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ModernistType.of(
                    size: 17,
                    weight: 900,
                    color: palette.ink,
                    tracking: -0.01,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '↓ ${trip.destino}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ModernistType.of(
                    size: 13,
                    weight: 600,
                    color: palette.note,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'V-${modernistFolio(trip.id)}',
            style: modernistMono(size: 10, color: palette.kicker),
          ),
        ],
      ),
    );
  }
}

// ─── Estado y fechas ────────────────────────────────────────────────────────

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: palette.ink,
                    width: ModernistRule.base,
                  ),
                ),
                child: Text(
                  trip.estado.displayName.toUpperCase(),
                  style: ModernistType.of(
                    size: 11,
                    weight: 800,
                    color: palette.ink,
                    tracking: 0.12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'CALIFICACIÓN',
                style: ModernistType.kicker(
                  size: 10,
                  tracking: 0.12,
                  color: palette.kicker,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                trip.calificacion?.toStringAsFixed(1) ?? '—',
                style: ModernistType.of(
                  size: 19,
                  weight: 900,
                  color: palette.ink,
                  tracking: -0.02,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _DateRow(label: 'INICIO', value: _fmtDate(trip.fechaInicio)),
          const SizedBox(height: 6),
          _DateRow(label: 'FIN', value: _fmtDate(trip.fechaFin)),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime? date) => date == null
      ? '—'
      : DateFormat('dd MMM yyyy · HH:mm', 'es_MX').format(date);
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: ModernistType.kicker(
              size: 10,
              tracking: 0.12,
              color: palette.kicker,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: ModernistType.of(
              size: 13,
              weight: 700,
              color: palette.ink,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Rejilla de cifras ──────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final points = trip.puntosObtenidos;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GridCell(
                  label: 'KM RECORRIDOS',
                  value: trip.kmRecorridos == null
                      ? '—'
                      : '${modernistNumber(trip.kmRecorridos!)} km',
                  right: true,
                  bottom: true,
                ),
                _GridCell(
                  label: 'RENDIMIENTO',
                  value: trip.rendimientoReal == null
                      ? '—'
                      : '${trip.rendimientoReal!.toStringAsFixed(1)} km/l',
                  bottom: true,
                ),
              ],
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GridCell(
                  label: 'LITROS DIESEL',
                  value: trip.litrosDiesel == null
                      ? '—'
                      : '${trip.litrosDiesel!.toStringAsFixed(1)} L',
                  right: true,
                ),
                _GridCell(
                  label: 'PUNTOS',
                  value: '${points >= 0 ? '+' : '-'}'
                      '${modernistNumber(points.abs())}',
                  valueColor:
                      points >= 0 ? palette.positive : palette.danger,
                  background: points >= 0
                      ? palette.positiveSurface
                      : palette.activeRowBg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.background,
    this.right = false,
    this.bottom = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Color? background;
  final bool right;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final rule = BorderSide(color: palette.ink, width: ModernistRule.base);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            right: right ? rule : BorderSide.none,
            bottom: bottom ? rule : BorderSide.none,
          ),
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
                size: 24,
                color: valueColor ?? palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ruta y leyenda ─────────────────────────────────────────────────────────

class _RouteBlock extends StatelessWidget {
  const _RouteBlock({required this.detail});

  final TripDetail detail;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final rule = BorderSide(color: palette.ink, width: ModernistRule.base);

    return Container(
      height: 190,
      decoration: BoxDecoration(border: Border(top: rule, bottom: rule)),
      child: GpsRouteIllustration(
        origen: detail.trip.origen.split(',').first.trim(),
        destino: detail.trip.destino.split(',').first.trim(),
        events: _events(detail),
      ),
    );
  }

  /// Reparte los eventos sobre el trazo según cuándo ocurrieron dentro del
  /// viaje. Sin fecha de inicio o fin no hay forma de situarlos, así que se
  /// distribuyen parejo para que al menos se vea cuántos hubo.
  static List<RouteEvent> _events(TripDetail detail) {
    final start = detail.trip.fechaInicio;
    final end = detail.trip.fechaFin;
    final span = (start != null && end != null)
        ? end.difference(start).inSeconds
        : 0;

    double position(DateTime at, int index, int total) {
      if (span <= 0) return total <= 1 ? 0.5 : (index + 1) / (total + 1);
      return (at.difference(start!).inSeconds / span).clamp(0.0, 1.0);
    }

    return [
      for (final (i, a) in detail.securityAlerts.indexed)
        RouteEvent(
          at: position(a.timestampAlerta, i, detail.securityAlerts.length),
          alert: true,
        ),
      for (final (i, inc) in detail.incidents.indexed)
        RouteEvent(
          at: position(inc.timestampIncidencia, i, detail.incidents.length),
          alert: false,
        ),
    ];
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.gpsCount});

  final int gpsCount;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          const _LegendItem(
            color: ModernistColors.red,
            label: 'Alerta de seguridad',
          ),
          _LegendItem(color: palette.neutralMark, label: 'Incidencia'),
          Text(
            '${modernistNumber(gpsCount)} puntos GPS',
            style: ModernistType.of(
              size: 11,
              weight: 700,
              color: palette.note,
              tracking: 0.06,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 11, height: 11, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: ModernistType.of(
            size: 11,
            weight: 700,
            color: palette.note,
            tracking: 0.06,
          ),
        ),
      ],
    );
  }
}

// ─── Incidencias ────────────────────────────────────────────────────────────

class _IncidentsSection extends StatelessWidget {
  const _IncidentsSection({required this.incidents});

  final List<TripIncident> incidents;

  @override
  Widget build(BuildContext context) {
    final impact = incidents.fold<int>(0, (s, i) => s + i.impactoPuntos);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: 'INCIDENCIAS', impact: impact),
          for (final incident in incidents) _IncidentRow(incident: incident),
        ],
      ),
    );
  }
}

class _IncidentRow extends StatelessWidget {
  const _IncidentRow({required this.incident});

  final TripIncident incident;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.rowDivider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: palette.neutralMark,
                width: ModernistRule.base,
              ),
            ),
            child: Text(
              'S${incident.severidad ?? 1}',
              style: ModernistType.of(
                size: 15,
                weight: 900,
                color: palette.note,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modernistLabel(incident.tipo),
                  style: ModernistType.of(
                    size: 15,
                    weight: 800,
                    color: palette.ink,
                    height: 1.2,
                  ),
                ),
                if (incident.descripcion case final text?) ...[
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: ModernistType.of(
                      size: 12,
                      weight: 500,
                      color: palette.note,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('dd/MM · HH:mm').format(
                  incident.timestampIncidencia,
                ),
                style: modernistMono(size: 10, color: palette.kicker),
              ),
              const SizedBox(height: 3),
              Text(
                '${incident.impactoPuntos} pts',
                style: ModernistType.of(
                  size: 12,
                  weight: 800,
                  color: palette.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Alertas de seguridad ───────────────────────────────────────────────────

class _AlertsSection extends StatelessWidget {
  const _AlertsSection({required this.alerts});

  final List<SecurityAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final impact = alerts.fold<int>(0, (s, a) => s + a.impactoPuntos);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: 'ALERTAS DE SEGURIDAD', impact: impact),
          for (final alert in alerts) _AlertRow(alert: alert),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final SecurityAlert alert;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final measured = alert.valorMedido;
    final threshold = alert.umbralPermitido;
    // El export escala la barra al 115 % del mayor de los dos valores, para
    // que el umbral nunca quede pegado al borde.
    final top = measured == null || threshold == null
        ? 0.0
        : (measured > threshold ? measured : threshold) * 1.15;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.rowDivider)),
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
                  modernistLabel(alert.tipo),
                  style: ModernistType.of(
                    size: 15,
                    weight: 800,
                    color: palette.ink,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('dd/MM · HH:mm').format(alert.timestampAlerta),
                style: modernistMono(size: 10, color: palette.kicker),
              ),
              const SizedBox(width: 12),
              Text(
                '${alert.impactoPuntos} pts',
                style: ModernistType.of(
                  size: 12,
                  weight: 800,
                  color: palette.danger,
                ),
              ),
            ],
          ),
          if (top > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_trim(measured!)} / ${_trim(threshold!)} '
                  '${_unitFor(alert.tipo)}',
                  style: ModernistType.of(
                    size: 12,
                    weight: 700,
                    color: palette.note,
                    tracking: 0.04,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AlertGauge(
                    value: measured / top,
                    threshold: threshold / top,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

  /// `SecurityAlert` no guarda la unidad; se deduce del tipo, que es como el
  /// export la presenta. Ver pendientes.
  static String _unitFor(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('velocidad')) return 'km/h';
    if (t.contains('frenado') || t.contains('aceleracion')) return 'm/s²';
    return '';
  }
}

/// Barra de la lectura contra el umbral, con la marca del límite encima.
class _AlertGauge extends StatelessWidget {
  const _AlertGauge({required this.value, required this.threshold});

  final double value;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: ColoredBox(color: palette.progressTrack)),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: constraints.maxWidth * value.clamp(0.0, 1.0),
              child: const ColoredBox(color: ModernistColors.red),
            ),
            Positioned(
              left: constraints.maxWidth * threshold.clamp(0.0, 1.0),
              top: -3,
              bottom: -3,
              width: 2,
              child: ColoredBox(color: palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Piezas compartidas ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.padding = 16});

  final String title;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, padding, 20, 18),
      child: Text(
        title,
        style: ModernistType.of(
          size: 13,
          weight: 900,
          color: palette.ink,
          tracking: 0.16,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.impact});

  final String title;
  final int impact;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: ModernistType.of(
                size: 13,
                weight: 900,
                color: palette.ink,
                tracking: 0.16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$impact pts',
            style: ModernistType.of(
              size: 12,
              weight: 800,
              color: palette.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'La línea negra marca el límite permitido. Las alertas y las '
        'incidencias ya están descontadas de los puntos del viaje.',
        style: ModernistType.of(
          size: 12,
          weight: 600,
          color: palette.kicker,
        ),
      ),
    );
  }
}
