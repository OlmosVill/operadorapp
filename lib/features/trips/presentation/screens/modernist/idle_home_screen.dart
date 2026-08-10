import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/profile/domain/entities/level_thresholds.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/home_provider.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/dock_scene.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/modernist_tab_bar.dart';

/// Home sin viaje asignado, implementando el export «Inicio Sin Viaje».
///
/// Son dos pantallas completas que se recorren con snap vertical: el almacén
/// con el tracto esperando, y debajo el detalle (progreso de nivel, últimos
/// viajes). El export lo resuelve con `scroll-snap-type: y mandatory` y
/// `scroll-snap-stop: always`, que es exactamente un `PageView` vertical.
///
/// Cubre los dos estados restantes de `HomeState`: el tablero del mes y el
/// regreso tras una ausencia.
class IdleHomeScreen extends ConsumerWidget {
  const IdleHomeScreen({
    required this.profile,
    required this.homeState,
    super.key,
  });

  final OperatorProfile profile;
  final HomeState homeState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ModernistPalette.of(context);
    final vm = _IdleHomeVm.from(profile: profile, homeState: homeState);
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
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  scrollDirection: Axis.vertical,
                  children: [
                    _DockSection(vm: vm),
                    _DetailSection(vm: vm),
                  ],
                ),
              ),
              // Aquí la regla superior la carga la barra: la sección de arriba
              // no termina en una.
              const ModernistTabBar(current: ModernistTab.inicio, ruled: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── View model ─────────────────────────────────────────────────────────────

class _IdleHomeVm {
  const _IdleHomeVm({
    required this.employeeNumber,
    required this.firstName,
    required this.level,
    required this.tripsMonth,
    required this.kmMonth,
    required this.pointsMonth,
    required this.streak,
    required this.recent,
    required this.nextLevel,
    required this.missingPoints,
    required this.progress,
  });

  factory _IdleHomeVm.from({
    required OperatorProfile profile,
    required HomeState homeState,
  }) {
    // El export documenta que esta vista cubre los dos estados. `Returning`
    // no trae km ni racha, así que esos quedan en cero.
    final (trips, points, km, streak) = switch (homeState) {
      HomeStateDashboard(
        :final monthTrips,
        :final totalKm,
        :final totalPoints,
        :final streak,
      ) =>
        (monthTrips, totalPoints, totalKm, streak),
      HomeStateReturning(:final recentTrips, :final recentPoints) => (
          recentTrips,
          recentPoints,
          recentTrips.fold<double>(0, (s, t) => s + (t.kmRecorridos ?? 0)),
          0,
        ),
      // La pantalla no se usa con viaje activo; se deja exhaustivo el switch.
      HomeStateActiveTrip() => (<Trip>[], 0, 0.0, 0),
    };

    // Los tres viajes cerrados más recientes, no los del mes: si el mes acaba
    // de empezar la lista quedaría vacía y el bloque se vería roto.
    final closed = trips
        .where((t) => t.estado == TripStatus.completado)
        .toList()
      ..sort((a, b) {
        final da = a.fechaFin ?? a.createdAt;
        final db = b.fechaFin ?? b.createdAt;
        return db.compareTo(da);
      });

    final next = profile.level.next;
    final target = nextLevelPoints(profile.level);
    final missing =
        target == null ? null : modernistNumber(target - profile.totalPoints);

    return _IdleHomeVm(
      employeeNumber: profile.employeeNumber,
      firstName: profile.fullName.split(' ').first,
      level: profile.level,
      tripsMonth: '${trips.length}',
      kmMonth: modernistNumber(km),
      pointsMonth: modernistNumber(points),
      streak: streak,
      recent: closed.take(3).map(_RecentTrip.from).toList(),
      nextLevel: next?.displayName ?? 'nivel máximo',
      // El nivel lo define el acumulado histórico, no el saldo disponible.
      missingPoints: missing == null ? '—' : '$missing pts',
      progress: levelProgress(profile.totalPoints, profile.level),
    );
  }

  final String employeeNumber;
  final String firstName;
  final OperatorLevel level;
  final String tripsMonth;
  final String kmMonth;
  final String pointsMonth;
  final int streak;
  final List<_RecentTrip> recent;
  final String nextLevel;
  final String missingPoints;

  /// Avance dentro del nivel actual, 0–1. Se llama así y no `levelProgress`
  /// para no tapar a la función homónima de `level_thresholds.dart`.
  final double progress;

  static const waitMessage = 'Operación te asigna la siguiente ruta y te '
      'avisamos aquí mismo.';

  String get streakNote => streak > 0
      ? 'Tu racha cuenta los días seguidos con viaje cerrado. Se rompe si '
          'pasas un día sin cerrar viaje.'
      : 'Cierra un viaje hoy para volver a empezar la racha.';
}

class _RecentTrip {
  const _RecentTrip({
    required this.id,
    required this.route,
    required this.meta,
    required this.points,
  });

  factory _RecentTrip.from(Trip trip) {
    final date = trip.fechaFin ?? trip.createdAt;
    return _RecentTrip(
      id: trip.id,
      route: '${trip.origen} → ${trip.destino}',
      meta: '${DateFormat('dd MMM', 'es_MX').format(date)} · '
          '${modernistNumber(trip.kmRecorridos ?? 0)} km',
      points: modernistNumber(trip.puntosObtenidos),
    );
  }

  final String id;
  final String route;
  final String meta;
  final String points;
}

// ─── Sección 1: el almacén ──────────────────────────────────────────────────

class _DockSection extends StatelessWidget {
  const _DockSection({required this.vm});

  final _IdleHomeVm vm;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return ColoredBox(
      color: palette.sectionBg,
      child: Column(
        children: [
          const DockBanner(),
          _IdleHeader(vm: vm),
          Expanded(
            child: DockScene(
              level: vm.level,
              tripsMonth: vm.tripsMonth,
              kmMonth: vm.kmMonth,
              pointsMonth: vm.pointsMonth,
              streak: vm.streak,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleHeader extends StatelessWidget {
  const _IdleHeader({required this.vm});

  final _IdleHomeVm vm;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    // Sin el chip de disponibilidad la cabecera dejó de ser un `Row`, y un
    // `Column` se encoge al ancho de su texto: hay que estirarla a mano para
    // que el fondo y la regla inferior lleguen a los dos bordes.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 12),
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMP. ${vm.employeeNumber} · SIN VIAJE ASIGNADO',
            style: ModernistType.kicker(
              size: 10,
              tracking: 0.14,
              color: palette.kicker,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Hola, ${vm.firstName}',
            style: ModernistType.of(
              size: 23,
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

// ─── Sección 2: el detalle ──────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.vm});

  final _IdleHomeVm vm;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return ColoredBox(
      color: palette.bg,
      child: Column(
        children: [
          _Ruled(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Text(
                _IdleHomeVm.waitMessage,
                style: ModernistType.of(
                  size: 15,
                  weight: 600,
                  color: palette.bodyMuted,
                  height: 1.35,
                ),
              ),
            ),
          ),
          _Ruled(child: _LevelProgressBlock(vm: vm)),
          Expanded(child: _RecentTrips(vm: vm)),
          const _BottomAction(),
        ],
      ),
    );
  }
}

/// Bloque con la regla inferior de 2 px.
class _Ruled extends StatelessWidget {
  const _Ruled({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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

class _LevelProgressBlock extends StatelessWidget {
  const _LevelProgressBlock({required this.vm});

  final _IdleHomeVm vm;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'RUMBO A ${vm.nextLevel.toUpperCase()}',
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
                'faltan ${vm.missingPoints}',
                style: ModernistType.of(
                  size: 12,
                  weight: 800,
                  color: palette.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 10,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: palette.progressTrack),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: constraints.maxWidth * vm.progress,
                      height: 10,
                      child: const ColoredBox(color: ModernistColors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _OutlinedRow(
            label: 'VER RUTA DE PREMIOS',
            onTap: () => unawaited(context.push('/rewards/catalog')),
          ),
        ],
      ),
    );
  }
}

class _OutlinedRow extends StatelessWidget {
  const _OutlinedRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: palette.ink, width: ModernistRule.base),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: ModernistType.of(
                  size: 12,
                  weight: 800,
                  color: palette.ink,
                  tracking: 0.1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '→',
              style: ModernistType.of(
                size: 14,
                weight: 900,
                color: palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTrips extends StatelessWidget {
  const _RecentTrips({required this.vm});

  final _IdleHomeVm vm;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TUS ÚLTIMOS VIAJES',
            style: ModernistType.of(
              size: 13,
              weight: 900,
              color: palette.ink,
              tracking: 0.16,
            ),
          ),
          const SizedBox(height: 4),
          for (final trip in vm.recent) _RecentTripRow(trip: trip),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 18),
            child: Text(
              vm.streakNote,
              style: ModernistType.of(
                size: 12,
                weight: 600,
                color: palette.kicker,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTripRow extends StatelessWidget {
  const _RecentTripRow({required this.trip});

  final _RecentTrip trip;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: () => unawaited(context.push('/trips/${trip.id}')),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.rowDivider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.route,
                    style: ModernistType.of(
                      size: 15,
                      weight: 800,
                      color: palette.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    trip.meta,
                    style: ModernistType.of(
                      size: 11,
                      weight: 600,
                      color: palette.note,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '+${trip.points}',
              style: ModernistType.of(
                size: 16,
                weight: 900,
                color: palette.positive,
                tracking: -0.02,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: GestureDetector(
        onTap: () => goToModernistTab(context, ModernistTab.viajes),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          alignment: Alignment.centerLeft,
          color: ModernistColors.red,
          child: Text(
            'VER MIS VIAJES',
            style: ModernistType.of(
              size: 12,
              weight: 800,
              color: ModernistColors.onRed,
              tracking: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
