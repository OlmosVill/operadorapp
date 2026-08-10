import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/core/theme/modernist/modernist_icons.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/profile/domain/entities/level_thresholds.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/modernist/redeem_flow.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/modernist_tab_bar.dart';
import 'package:operadorapp/features/trucks/domain/entities/truck.dart';
import 'package:operadorapp/features/trucks/presentation/providers/trucks_provider.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

/// Perfil del operador, implementando el export «Perfil Operador».
///
/// Sustituye a la `ProfileScreen` anterior y es la cuarta pestaña de la barra
/// Modernist. Reúne nivel, saldo de puntos, los premios más cercanos y la
/// ficha del operador.
class OperatorProfileScreen extends ConsumerStatefulWidget {
  const OperatorProfileScreen({super.key});

  @override
  ConsumerState<OperatorProfileScreen> createState() =>
      _OperatorProfileScreenState();
}

class _OperatorProfileScreenState extends ConsumerState<OperatorProfileScreen>
    with RedeemFlowMixin {
  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final profileAsync = ref.watch(profileProvider);
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
          child: profileAsync.when(
            loading: () => const AppLoadingWidget(message: 'Cargando...'),
            error: (_, __) => const SizedBox.shrink(),
            data: _buildBody,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(OperatorProfile profile) {
    final premios = ref.watch(premiosProvider).value ?? const <Premio>[];
    final trips = ref.watch(tripsProvider).value ?? const <Trip>[];
    final trucks = ref.watch(truckSummariesProvider).value;

    final reachable = _reachable(premios);

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _ProfileHeader(profile: profile),
                  _LevelBanner(profile: profile),
                  _PointsRow(profile: profile),
                  _RewardsSection(
                    premios: reachable,
                    available: profile.availablePoints,
                    level: profile.level,
                    onRedeem: startRedeem,
                  ),
                  _FactsSection(
                    truck: _currentTruck(trucks),
                    trips: trips,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const ModernistTabBar(
              current: ModernistTab.perfil,
              ruled: true,
            ),
          ],
        ),
        if (buildRedeemSheet(
              operadorId: profile.id,
              availablePoints: profile.availablePoints,
            )
            case final sheet?)
          sheet,
      ],
    );
  }

  /// Los tres premios más baratos del catálogo, que es lo que el export
  /// entiende por «a tu alcance».
  static List<Premio> _reachable(List<Premio> premios) {
    final active = premios.where((p) => p.activo).toList()
      ..sort((a, b) => a.costoPuntos.compareTo(b.costoPuntos));
    return active.take(3).toList();
  }

  /// «T-003 Freightliner Cascadia» a partir del tracto en uso.
  static String? _currentTruck(List<TruckSummary>? trucks) {
    if (trucks == null || trucks.isEmpty) return null;
    final current = trucks.firstWhere(
      (t) => t.esActual,
      orElse: () => trucks.first,
    );
    return [current.numeroEconomico, current.marca, current.modelo]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');
  }
}

// ─── Cabecera ───────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final OperatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
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
                  'OPERADOR · EMP. ${profile.employeeNumber}',
                  style: ModernistType.kicker(
                    size: 11,
                    tracking: 0.14,
                    color: palette.kicker,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.fullName,
                  style: ModernistType.of(
                    size: 29,
                    weight: 800,
                    color: palette.ink,
                    tracking: -0.02,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle(profile),
                  style: ModernistType.of(
                    size: 12,
                    weight: 500,
                    color: palette.note,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SettingsButton(),
              const SizedBox(height: 8),
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(6),
                alignment: Alignment.bottomLeft,
                color: ModernistColors.red,
                child: Text(
                  _initials(profile.fullName),
                  style: ModernistType.of(
                    size: 22,
                    weight: 900,
                    color: ModernistColors.onRed,
                    tracking: -0.02,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String name) => name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  /// «Base Monterrey · 4 años 6 meses». La antigüedad sale de `fecha_ingreso`.
  static String _subtitle(OperatorProfile profile) {
    final base = profile.base;
    final months = _monthsSince(profile.startDate);
    final years = months ~/ 12;
    final rest = months % 12;

    final tenure = [
      if (years > 0) '$years ${years == 1 ? 'año' : 'años'}',
      if (rest > 0) '$rest ${rest == 1 ? 'mes' : 'meses'}',
    ].join(' ');

    return [
      if (base != null && base.isNotEmpty) 'Base $base',
      if (tenure.isNotEmpty) tenure,
    ].join(' · ');
  }

  static int _monthsSince(DateTime from) {
    final now = DateTime.now();
    var months = (now.year - from.year) * 12 + now.month - from.month;
    if (now.day < from.day) months--;
    return months < 0 ? 0 : months;
  }
}

/// Acceso a Ajustes. Vive aquí porque el export cambió la cuarta pestaña por
/// Perfil y la configuración se quedó sin entrada propia.
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: () => unawaited(context.push('/settings')),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: palette.ink, width: ModernistRule.base),
        ),
        child: ModernistGear(color: palette.ink, size: 22),
      ),
    );
  }
}

// ─── Banner de nivel ────────────────────────────────────────────────────────

class _LevelBanner extends StatelessWidget {
  const _LevelBanner({required this.profile});

  final OperatorProfile profile;

  @override
  Widget build(BuildContext context) {
    const white = ModernistColors.onRed;
    final next = profile.level.next;
    final target = nextLevelPoints(profile.level);
    final order = OperatorLevel.values.indexOf(profile.level) + 1;
    final missing =
        target == null ? 0 : (target - profile.totalPoints).clamp(0, 1 << 31);

    return Container(
      width: double.infinity,
      color: ModernistColors.red,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: _kicker('NIVEL ACTUAL')),
              _kicker('$order DE 5'),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ModernistColors.level(profile.level),
                  border: Border.all(
                    color: white,
                    width: ModernistRule.base,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profile.level.displayName.toUpperCase(),
                  style: ModernistType.of(
                    size: 52,
                    weight: 900,
                    color: white,
                    tracking: -0.03,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    next == null
                        ? 'Nivel máximo de la flota'
                        : 'Rumbo a ${next.displayName}',
                    textAlign: TextAlign.right,
                    style: ModernistType.of(
                      size: 13,
                      weight: 600,
                      color: white,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Progress(value: levelProgress(profile.totalPoints, profile.level)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${modernistNumber(profile.totalPoints)} / '
                  '${target == null ? '—' : modernistNumber(target)} PTS',
                  style: _footStyle,
                ),
              ),
              Text('FALTAN ${modernistNumber(missing)} PTS', style: _footStyle),
            ],
          ),
        ],
      ),
    );
  }

  static final TextStyle _footStyle = ModernistType.of(
    size: 12,
    weight: 700,
    color: ModernistColors.onRed,
    tracking: 0.04,
  );

  Widget _kicker(String text) => Opacity(
        opacity: 0.85,
        child: Text(
          text,
          style: ModernistType.kicker(
            size: 11,
            tracking: 0.14,
            color: ModernistColors.onRed,
          ),
        ),
      );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: ModernistColors.onRed.withValues(alpha: 0.3),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: const Cubic(0.2, 0.8, 0.2, 1),
              builder: (context, filled, _) => Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth * filled,
                  height: 10,
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

// ─── Saldos ─────────────────────────────────────────────────────────────────

class _PointsRow extends StatelessWidget {
  const _PointsRow({required this.profile});

  final OperatorProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

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
            _PointsCell(
              label: 'DISPONIBLES',
              value: modernistNumber(profile.availablePoints),
              note: 'pts para canjear',
              divider: true,
            ),
            _PointsCell(
              label: 'GANADOS',
              value: modernistNumber(profile.totalPoints),
              note: 'históricos totales',
              // El acumulado va apagado: el que se puede gastar es el otro.
              valueColor: palette.note,
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsCell extends StatelessWidget {
  const _PointsCell({
    required this.label,
    required this.value,
    required this.note,
    this.valueColor,
    this.divider = false,
  });

  final String label;
  final String value;
  final String note;
  final Color? valueColor;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                size: 11,
                tracking: 0.12,
                color: palette.kicker,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: ModernistType.figure(
                size: 30,
                color: valueColor ?? palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: ModernistType.of(
                size: 11,
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

// ─── Premios a tu alcance ───────────────────────────────────────────────────

class _RewardsSection extends StatelessWidget {
  const _RewardsSection({
    required this.premios,
    required this.available,
    required this.level,
    required this.onRedeem,
  });

  final List<Premio> premios;
  final int available;
  final OperatorLevel level;
  final void Function(Premio) onRedeem;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  'PREMIOS A TU ALCANCE',
                  style: ModernistType.of(
                    size: 15,
                    weight: 800,
                    color: palette.ink,
                    tracking: 0.1,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => goToModernistTab(context, ModernistTab.premios),
                child: Text(
                  'VER TODOS',
                  style: ModernistType.of(
                    size: 12,
                    weight: 700,
                    // Es un `<a>` en el export.
                    color: palette.link,
                    tracking: 0.08,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (premios.isEmpty)
            Text(
              'Todavía no hay premios en el catálogo.',
              style: ModernistType.of(
                size: 12,
                weight: 600,
                color: palette.kicker,
              ),
            ),
          for (final premio in premios)
            _RewardRow(
              premio: premio,
              available: available,
              level: level,
              onRedeem: () => onRedeem(premio),
            ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.premio,
    required this.available,
    required this.level,
    required this.onRedeem,
  });

  final Premio premio;
  final int available;
  final OperatorLevel level;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    final required = premio.nivelMinimo;
    final locked = required != null &&
        OperatorLevel.values.indexOf(level) <
            OperatorLevel.values.indexOf(required);
    final affordable = !locked && available >= premio.costoPuntos;

    final meta = locked
        ? 'Requiere nivel ${required.displayName} · '
            '${modernistNumber(premio.costoPuntos)} pts'
        : affordable
            ? '${modernistNumber(premio.costoPuntos)} pts · disponible ahora'
            : 'Te faltan '
                '${modernistNumber(premio.costoPuntos - available)} pts';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.rowDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  premio.nombre,
                  style: ModernistType.of(
                    size: 15,
                    weight: 700,
                    color: locked ? palette.kicker : palette.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: ModernistType.of(
                    size: 12,
                    weight: 600,
                    color: palette.kicker,
                    tracking: 0.04,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: affordable ? onRedeem : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: affordable ? ModernistColors.red : null,
                border: Border.all(
                  color: affordable
                      ? ModernistColors.red
                      : locked
                          ? palette.progressTrack
                          : palette.ink,
                  width: ModernistRule.base,
                ),
              ),
              child: Text(
                locked
                    ? 'BLOQUEADO'
                    : affordable
                        ? 'CANJEAR'
                        : 'SEGUIR',
                style: ModernistType.of(
                  size: 12,
                  weight: 800,
                  color: affordable
                      ? ModernistColors.onRed
                      : locked
                          ? palette.disabled
                          : palette.ink,
                  tracking: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mis datos ──────────────────────────────────────────────────────────────

class _FactsSection extends StatelessWidget {
  const _FactsSection({required this.truck, required this.trips});

  final String? truck;
  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    final closed =
        trips.where((t) => t.estado == TripStatus.completado).toList();
    final rendimientos =
        closed.map((t) => t.rendimientoReal).whereType<double>().toList();
    final average = rendimientos.isEmpty
        ? null
        : rendimientos.reduce((a, b) => a + b) / rendimientos.length;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MIS DATOS',
            style: ModernistType.of(
              size: 15,
              weight: 800,
              color: palette.ink,
              tracking: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          _Fact(label: 'Tracto asignado', value: truck ?? '—', ruled: true),
          _Fact(
            label: 'Rendimiento promedio',
            value: average == null ? '—' : '${average.toStringAsFixed(1)} km/l',
            ruled: true,
          ),
          _Fact(label: 'Viajes completados', value: '${closed.length}'),
          const SizedBox(height: 14),
          // Añadido: ningún export enlaza al ranking, y al quitar el AppBar
          // del Home se quedó sin puerta de entrada. Ver pendientes.
          const _RankingLink(),
        ],
      ),
    );
  }
}

class _RankingLink extends StatelessWidget {
  const _RankingLink();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: () => unawaited(context.push('/ranking')),
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
                'VER RANKING DE LA FLOTA',
                style: ModernistType.of(
                  size: 12,
                  weight: 800,
                  color: palette.ink,
                  tracking: 0.1,
                ),
              ),
            ),
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

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    this.ruled = false,
  });

  final String label;
  final String value;
  final bool ruled;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: ruled
            ? Border(bottom: BorderSide(color: palette.rowDivider))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ModernistType.of(
                size: 13,
                weight: 600,
                color: palette.note,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: ModernistType.of(
              size: 13,
              weight: 700,
              color: palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}
