import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/domain/entities/trip_detail.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trips/presentation/providers/truck_scene_provider.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/modernist_tab_bar.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/route_map_illustration.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/truck_scene.dart';

/// Home con viaje en curso, implementando el export «Inicio Viaje Activo» del
/// sistema Modernist.
///
/// Es la primera pantalla migrada al nuevo diseño, así que no consume
/// `Theme.of(context)`: todos los colores salen de [ModernistColors] y la
/// pantalla se ve igual con la app en claro o en oscuro. Cuando se porte la
/// variante oscura del export, esto pasa a resolverse por tema.
class ActiveTripHomeScreen extends ConsumerStatefulWidget {
  const ActiveTripHomeScreen({
    required this.profile,
    required this.trip,
    super.key,
  });

  final OperatorProfile profile;
  final Trip trip;

  @override
  ConsumerState<ActiveTripHomeScreen> createState() =>
      _ActiveTripHomeScreenState();
}

class _ActiveTripHomeScreenState extends ConsumerState<ActiveTripHomeScreen> {
  bool _reportOpen = false;
  String? _sentReason;

  /// Estado mecánico elegido desde el panel de reporte. Vive solo en memoria:
  /// todavía no hay repositorio de reportes que lo persista.
  MechanicalState? _mechanicalOverride;
  Timer? _closeTimer;

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _pickReason(_Reason reason) {
    setState(() => _sentReason = reason.label);
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _reportOpen = false;
        _sentReason = null;
        _mechanicalOverride = reason.mechanical;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(tripDetailProvider(widget.trip.id)).value;
    final vm = _ActiveTripVm.from(
      profile: widget.profile,
      trip: widget.trip,
      detail: detail,
      mechanicalOverride: _mechanicalOverride,
      timeOfDay: ref.watch(sceneTimeOfDayProvider),
    );

    final palette = ModernistPalette.of(context);
    // `SystemUiOverlayStyle.dark` = iconos oscuros, o sea para fondo claro.
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
                  _Header(vm: vm),
                  _TripBanner(vm: vm),
                  // El export reparte el espacio sobrante 1.05 : 1 entre la
                  // escena y el mapa.
                  Expanded(
                    flex: 21,
                    child: _Framed(
                      child: TruckScene(
                        speedKmh: vm.speedKmh,
                        timeOfDay: vm.timeOfDay,
                        mechanical: vm.mechanical,
                        progress: vm.progress,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 20,
                    child: _Framed(
                      child: RouteMapIllustration(
                        origen: vm.origenCorto,
                        destino: vm.destinoCorto,
                        progress: vm.progress,
                      ),
                    ),
                  ),
                  _StatsRow(vm: vm),
                  _Actions(
                    onDetail: () => context.push('/trips/${widget.trip.id}'),
                    onReport: () => setState(() => _reportOpen = true),
                  ),
                  // Aquí no lleva regla propia: la botonera de arriba ya
                  // termina en una.
                  const ModernistTabBar(current: ModernistTab.inicio),
                ],
              ),
              if (_reportOpen)
                _ReportOverlay(
                  sentReason: _sentReason,
                  onPick: _pickReason,
                  onClose: () => setState(() {
                    _reportOpen = false;
                    _sentReason = null;
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── View model ─────────────────────────────────────────────────────────────

final _kmFormat = NumberFormat.decimalPattern('es_MX');

/// Traduce el viaje real a los valores que pide el diseño.
///
/// Lo que el export inventa y la app todavía no tiene queda marcado en el
/// código y listado en `docs/features/modernist-home.md`.
class _ActiveTripVm {
  const _ActiveTripVm({
    required this.employeeNumber,
    required this.firstName,
    required this.level,
    required this.folio,
    required this.statusLabel,
    required this.origen,
    required this.destino,
    required this.km,
    required this.kmTotal,
    required this.progress,
    required this.rendimiento,
    required this.alerts,
    required this.alertsNote,
    required this.estimatedPoints,
    required this.speedKmh,
    required this.timeOfDay,
    required this.mechanical,
  });

  factory _ActiveTripVm.from({
    required OperatorProfile profile,
    required Trip trip,
    required TripDetail? detail,
    required MechanicalState? mechanicalOverride,
    required double timeOfDay,
  }) {
    final km = trip.kmRecorridos ?? 0;
    final kmTotal = trip.kmEsperados ?? 0;
    final alerts = detail?.securityAlerts.length ?? 0;

    final mechanical = mechanicalOverride ?? _mechanicalFrom(detail);
    // TODO(olmosvill): sin punto GPS con velocidad se asume la nominal del
    // export para que la escena no aparezca detenida. Ver pendientes.
    final speed = detail?.gpsPoints.lastOrNull?.velocidadKmh ?? 76;
    final stopped = mechanical == MechanicalState.inService ||
        mechanical == MechanicalState.crashed ||
        speed <= 0;

    return _ActiveTripVm(
      employeeNumber: profile.employeeNumber,
      firstName: profile.fullName.split(' ').first,
      level: profile.level,
      folio: modernistFolio(trip.id),
      statusLabel: _statusLabel(
        estado: trip.estado,
        stopped: stopped,
        mechanical: mechanical,
      ),
      origen: trip.origen,
      destino: trip.destino,
      km: km,
      kmTotal: kmTotal,
      progress: kmTotal <= 0 ? 0 : (km / kmTotal).clamp(0.0, 1.0),
      rendimiento: trip.rendimientoReal,
      alerts: alerts,
      alertsNote: _alertsNote(detail, alerts),
      // TODO(olmosvill): el cálculo real vive en Edge Functions. Mientras el
      // viaje no cierra no hay saldo, así que se muestra la fórmula del
      // mockup como estimado visual, nunca como saldo acreditado.
      estimatedPoints:
          trip.puntosObtenidos > 0 ? trip.puntosObtenidos : 142 - alerts * 5,
      speedKmh: speed,
      timeOfDay: timeOfDay,
      mechanical: mechanical,
    );
  }

  final String employeeNumber;
  final String firstName;
  final OperatorLevel level;
  final String folio;
  final String statusLabel;
  final String origen;
  final String destino;
  final double km;
  final double kmTotal;
  final double progress;
  final double? rendimiento;
  final int alerts;
  final String alertsNote;
  final int estimatedPoints;
  final double speedKmh;
  final double timeOfDay;
  final MechanicalState mechanical;

  String get kmFmt => _kmFormat.format(km.round());
  String get kmTotalFmt => _kmFormat.format(kmTotal.round());
  String get remainingFmt {
    final left = (kmTotal - km).round();
    return _kmFormat.format(left < 0 ? 0 : left);
  }

  String get rendimientoFmt => rendimiento?.toStringAsFixed(1) ?? '—';

  /// El mapa rotula solo la ciudad: «Monterrey, NL» → «Monterrey».
  String get origenCorto => origen.split(',').first.trim();
  String get destinoCorto => destino.split(',').first.trim();

  /// El export solo contempla «Viaje en curso», pero el Inicio también recibe
  /// viajes en `asignado` (ver `homeStateProvider`). Anunciar como en curso uno
  /// que el operador no ha arrancado sería mentirle, así que lleva su propio
  /// rótulo.
  static String _statusLabel({
    required TripStatus estado,
    required bool stopped,
    required MechanicalState mechanical,
  }) {
    if (mechanical == MechanicalState.crashed) return 'Viaje detenido';
    if (estado == TripStatus.asignado) return 'Viaje asignado';
    if (stopped) return 'Viaje en pausa';
    return 'Viaje en curso';
  }

  /// `TripIncident` no expone el estado del reporte, así que se consideran
  /// todas las incidencias del viaje y no solo las abiertas. Ver pendientes.
  static MechanicalState _mechanicalFrom(TripDetail? detail) {
    final tipos =
        detail?.incidents.map((i) => i.tipo.toLowerCase()) ?? const <String>[];
    // Prioridad: choque > mantenimiento > llanta.
    if (tipos.contains('choque')) return MechanicalState.crashed;
    if (tipos.contains('mantenimiento')) return MechanicalState.inService;
    if (tipos.contains('llanta')) return MechanicalState.flatTire;
    return MechanicalState.ok;
  }

  static String _alertsNote(TripDetail? detail, int alerts) {
    if (alerts == 0) return 'sin eventos';
    if (alerts > 1) return 'eventos de manejo';
    return detail!.securityAlerts.first.tipo.replaceAll('_', ' ');
  }

}

// ─── Secciones ──────────────────────────────────────────────────────────────

/// Envuelve una sección con la regla inferior de 2 px que separa todo el
/// diseño.
class _Framed extends StatelessWidget {
  const _Framed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // En primer plano: la escena y el mapa pintan a sangre, así que una
    // decoración de fondo quedaría tapada por debajo del dibujo.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ModernistPalette.of(context).ink,
            width: ModernistRule.base,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vm});

  final _ActiveTripVm vm;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: palette.ink,
            width: ModernistRule.base,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPERADORAPP · EMP. ${vm.employeeNumber}',
                  style: ModernistType.kicker(
                    size: 11,
                    tracking: 0.14,
                    color: palette.kicker,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Hola, ${vm.firstName}',
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
          ),
          const SizedBox(width: 12),
          _LevelChip(level: vm.level),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final OperatorLevel level;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: () => goToModernistTab(context, ModernistTab.perfil),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(
            color: palette.ink,
            width: ModernistRule.base,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: ModernistColors.level(level),
                border: Border.all(color: palette.ink),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NIVEL',
                  style: ModernistType.kicker(
                    size: 9,
                    tracking: 0.12,
                    color: palette.kicker,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  level.displayName.toUpperCase(),
                  style: ModernistType.of(
                    size: 14,
                    weight: 900,
                    // El chip es un `<a>` en el export y este span no declara
                    // color: hereda el del enlace, no la tinta.
                    color: palette.link,
                    tracking: 0.04,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripBanner extends StatelessWidget {
  const _TripBanner({required this.vm});

  final _ActiveTripVm vm;

  @override
  Widget build(BuildContext context) {
    // El banner no cambia entre claro y oscuro: los dos exports lo dejan en
    // rojo de marca con texto blanco.
    const white = ModernistColors.onRed;

    return Container(
      width: double.infinity,
      color: ModernistColors.red,
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _PulsingDot(),
              const SizedBox(width: 9),
              Text(
                vm.statusLabel.toUpperCase(),
                style: ModernistType.of(
                  size: 12,
                  weight: 800,
                  color: white,
                  tracking: 0.16,
                ),
              ),
              const Spacer(),
              Text(
                'V-${vm.folio}',
                style: ModernistType.of(
                  size: 12,
                  weight: 700,
                  color: white,
                  tracking: 0.08,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: _place(vm.origen, TextAlign.left)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '→',
                  style: ModernistType.of(
                    size: 19,
                    weight: 700,
                    color: white.withValues(alpha: 0.7),
                    height: 1.1,
                  ),
                ),
              ),
              Flexible(child: _place(vm.destino, TextAlign.right)),
            ],
          ),
          const SizedBox(height: 11),
          _ProgressBar(value: vm.progress),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${vm.kmFmt} DE ${vm.kmTotalFmt} KM',
                style: _footStyle,
              ),
              Text('FALTA ${vm.remainingFmt} KM', style: _footStyle),
            ],
          ),
        ],
      ),
    );
  }

  static final TextStyle _footStyle = ModernistType.of(
    size: 11,
    weight: 700,
    color: ModernistColors.onRed,
    tracking: 0.08,
  );

  /// Origen y destino van siempre en una línea, como en el export. Un par como
  /// «Monterrey, NL → Guadalajara, JAL» llena el ancho al ras, así que en vez
  /// de partirse en dos renglones —lo que engordaría el banner y le robaría
  /// altura a la escena y al mapa— se encoge lo mínimo necesario.
  Widget _place(String text, TextAlign align) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align == TextAlign.right
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          style: ModernistType.of(
            size: 19,
            weight: 900,
            color: ModernistColors.onRed,
            tracking: -0.02,
            height: 1.1,
          ),
        ),
      );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: ModernistColors.onRed.withValues(alpha: 0.3),
            ),
            // `transition: width .9s cubic-bezier(.2,.8,.2,1)` del export.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: const Cubic(0.2, 0.8, 0.2, 1),
              builder: (context, filled, _) => Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth * filled,
                  height: 8,
                  child: const ColoredBox(color: ModernistColors.onRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    // @keyframes pulseDot: scale .7 → 1.35, opacidad 1 → .55
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
    return SizedBox(
      width: 11,
      height: 11,
      child: AnimatedBuilder(
        animation: curve,
        builder: (context, _) => Transform.scale(
          scale: 0.7 + 0.65 * curve.value,
          child: Opacity(
            opacity: 1 - 0.45 * curve.value,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: ModernistColors.onRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.vm});

  final _ActiveTripVm vm;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: palette.ink,
            width: ModernistRule.base,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatCell(
              label: 'RENDIMIENTO',
              value: vm.rendimientoFmt,
              note: 'km/l · meta 4.5',
              valueColor: palette.ink,
              divider: true,
            ),
            _StatCell(
              label: 'ALERTAS',
              value: '${vm.alerts}',
              note: vm.alertsNote,
              valueColor: vm.alerts == 0 ? palette.ink : palette.danger,
              divider: true,
            ),
            _StatCell(
              label: 'PUNTOS EST.',
              value: '+${vm.estimatedPoints}',
              note: 'al completar',
              valueColor: palette.positive,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.note,
    required this.valueColor,
    this.divider = false,
  });

  final String label;
  final String value;
  final String note;
  final Color valueColor;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
              style: ModernistType.figure(size: 23, color: valueColor),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ModernistType.of(
                size: 10,
                weight: 600,
                color: palette.note,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onDetail, required this.onReport});

  final VoidCallback onDetail;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(
          bottom: BorderSide(
            color: palette.ink,
            width: ModernistRule.base,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BlockButton(
              label: 'VER DETALLE DEL VIAJE',
              onTap: onDetail,
              filled: true,
            ),
          ),
          const SizedBox(width: 10),
          _BlockButton(label: 'REPORTAR', onTap: onReport),
        ],
      ),
    );
  }
}

class _BlockButton extends StatelessWidget {
  const _BlockButton({
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
          // El botón primario se queda en rojo de marca en los dos temas.
          color: filled ? ModernistColors.red : null,
          border: filled
              ? null
              : Border.all(
                  color: palette.ink,
                  width: ModernistRule.base,
                ),
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

// ─── Panel de reporte ───────────────────────────────────────────────────────

class _Reason {
  const _Reason(this.label, this.meta, this.mechanical);

  final String label;
  final String meta;
  final MechanicalState mechanical;
}

/// `reportes.tipo` → MechanicalState, según docs/features/truck-animation.md.
const _reasons = <_Reason>[
  _Reason('Falla mecánica', 'Severidad alta', MechanicalState.inService),
  _Reason('Llanta ponchada', 'Severidad alta', MechanicalState.flatTire),
  _Reason('Tráfico o bloqueo', 'Severidad media', MechanicalState.ok),
  _Reason('Clima adverso', 'Severidad media', MechanicalState.ok),
];

class _ReportOverlay extends StatelessWidget {
  const _ReportOverlay({
    required this.sentReason,
    required this.onPick,
    required this.onClose,
  });

  final String? sentReason;
  final void Function(_Reason) onPick;
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
                // Absorbe el tap para que tocar el panel no lo cierre.
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
                        'REPORTAR EN RUTA',
                        style: ModernistType.kicker(
                          size: 11,
                          tracking: 0.14,
                          color: palette.kicker,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '¿Qué está pasando?',
                        style: ModernistType.of(
                          size: 23,
                          weight: 900,
                          color: palette.ink,
                          tracking: -0.02,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: palette.ink,
                              width: ModernistRule.base,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final reason in _reasons)
                              _ReasonRow(
                                reason: reason,
                                sent: sentReason == reason.label,
                                onTap: () => onPick(reason),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CancelButton(onTap: onClose),
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
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.reason,
    required this.sent,
    required this.onTap,
  });

  final _Reason reason;
  final bool sent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.rowDivider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                sent ? '${reason.label} — enviado' : reason.label,
                style: ModernistType.of(
                  size: 15,
                  weight: 700,
                  color: sent ? palette.danger : palette.ink,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              sent ? 'REGISTRADO' : reason.meta.toUpperCase(),
              style: ModernistType.kicker(
                size: 12,
                tracking: 0.08,
                color: palette.kicker,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          border: Border.all(
            color: palette.ink,
            width: ModernistRule.base,
          ),
        ),
        child: Text(
          'CANCELAR',
          style: ModernistType.of(
            size: 13,
            weight: 800,
            color: palette.ink,
            tracking: 0.12,
          ),
        ),
      ),
    );
  }
}
