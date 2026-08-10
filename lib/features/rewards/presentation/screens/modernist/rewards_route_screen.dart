import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/profile/domain/entities/level_thresholds.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/rewards/domain/entities/premio.dart';
import 'package:operadorapp/features/rewards/presentation/providers/rewards_provider.dart';
import 'package:operadorapp/features/rewards/presentation/widgets/modernist/redeem_flow.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/modernist_tab_bar.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

/// Catálogo de premios como una ruta que asciende, implementando el export
/// «Premios Ruta».
///
/// Sustituye a `RewardsScreen` y a `RewardsRoadmapScreen`: el export fusiona
/// catálogo y roadmap en una sola vista. El hito más caro va arriba y el
/// operador abajo, así que la pantalla **abre desplazada hasta el final**,
/// donde está su posición.
class RewardsRouteScreen extends ConsumerStatefulWidget {
  const RewardsRouteScreen({super.key});

  @override
  ConsumerState<RewardsRouteScreen> createState() => _RewardsRouteScreenState();
}

class _RewardsRouteScreenState extends ConsumerState<RewardsRouteScreen>
    with RedeemFlowMixin {
  /// `null` = «Todos».
  OperatorLevel? _filter;

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
    final rows = buildRewardRoute(
      premios: premios,
      level: profile.level,
      available: profile.availablePoints,
      filter: _filter,
    );

    return Stack(
      children: [
        Column(
          children: [
            _RouteHeader(
              available: profile.availablePoints,
              filter: _filter,
              onFilter: (level) => setState(() => _filter = level),
            ),
            Expanded(
              // Invertida a propósito: la ruta asciende y el operador está
              // hasta abajo, así que el desplazamiento cero ya es su posición.
              // Perseguir `maxScrollExtent` con un `jumpTo` no sirve aquí —
              // un `ListView.builder` solo conoce lo que ya construyó.
              child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.zero,
                itemCount: rows.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return const _RouteFooter();
                  return switch (rows[rows.length - index]) {
                    RewardRouteBanner(:final level, :final unlocked) =>
                      _LevelBanner(level: level, unlocked: unlocked),
                    RewardRouteMilestone(:final premio, :final state) =>
                      _Milestone(
                        premio: premio,
                        state: state,
                        available: profile.availablePoints,
                        onRedeem: () => startRedeem(premio),
                      ),
                    RewardRouteMarker(:final balance) =>
                      _PositionMarker(balance: balance),
                  };
                },
              ),
            ),
            const ModernistTabBar(
              current: ModernistTab.premios,
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
}

// ─── Modelo de la ruta ──────────────────────────────────────────────────────

/// Situación de un hito respecto al operador.
enum MilestoneState {
  /// Alcanzable ya: nivel suficiente y saldo suficiente.
  open,

  /// Nivel suficiente pero falta saldo. Es el siguiente objetivo si además
  /// es el más barato de los que faltan.
  saving,

  /// El nivel todavía no da.
  locked,

  /// Es el próximo hito que se puede lograr.
  target,
}

sealed class RewardRouteRow {
  const RewardRouteRow();
}

class RewardRouteBanner extends RewardRouteRow {
  const RewardRouteBanner({required this.level, required this.unlocked});

  final OperatorLevel level;
  final bool unlocked;
}

class RewardRouteMilestone extends RewardRouteRow {
  const RewardRouteMilestone({required this.premio, required this.state});

  final Premio premio;
  final MilestoneState state;
}

class RewardRouteMarker extends RewardRouteRow {
  const RewardRouteMarker({required this.balance});

  final int balance;
}

/// Arma la ruta: hitos ordenados de más caro (arriba) a más barato (abajo),
/// con una banda por cada nivel y el marcador del operador al final.
///
/// Es una función de nivel superior para poder probarla sin construir la
/// pantalla, igual que `filterAndSortPremios()` en la versión anterior.
@visibleForTesting
List<RewardRouteRow> buildRewardRoute({
  required List<Premio> premios,
  required OperatorLevel level,
  required int available,
  OperatorLevel? filter,
}) {
  final levelIndex = OperatorLevel.values.indexOf(level);

  int rank(Premio p) =>
      OperatorLevel.values.indexOf(p.nivelMinimo ?? OperatorLevel.plata);

  bool isOpen(Premio p) =>
      available >= p.costoPuntos && levelIndex >= rank(p);

  final visible = premios
      .where((p) => p.activo)
      .where(
        (p) =>
            filter == null || (p.nivelMinimo ?? OperatorLevel.plata) == filter,
      )
      .toList()
    ..sort((a, b) => a.costoPuntos.compareTo(b.costoPuntos));

  // El objetivo es el hito más barato que todavía no se alcanza.
  final target = visible.where((p) => !isOpen(p)).firstOrNull;

  final rows = <RewardRouteRow>[];
  OperatorLevel? previous;

  for (final premio in visible.reversed) {
    final tier = premio.nivelMinimo ?? OperatorLevel.plata;
    if (tier != previous) {
      previous = tier;
      rows.add(
        RewardRouteBanner(
          level: tier,
          unlocked: OperatorLevel.values.indexOf(tier) <= levelIndex,
        ),
      );
    }

    rows.add(
      RewardRouteMilestone(
        premio: premio,
        state: switch (premio) {
          _ when isOpen(premio) => MilestoneState.open,
          _ when levelIndex < rank(premio) => MilestoneState.locked,
          _ when identical(premio, target) => MilestoneState.target,
          _ => MilestoneState.saving,
        },
      ),
    );
  }

  return rows..add(RewardRouteMarker(balance: available));
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// ─── Cabecera y filtros ─────────────────────────────────────────────────────

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({
    required this.available,
    required this.filter,
    required this.onFilter,
  });

  final int available;
  final OperatorLevel? filter;
  final void Function(OperatorLevel?) onFilter;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RUTA DE PREMIOS',
                        style: ModernistType.kicker(
                          size: 11,
                          tracking: 0.14,
                          color: palette.kicker,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sigue subiendo',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DISPONIBLES',
                      style: ModernistType.kicker(
                        size: 10,
                        tracking: 0.12,
                        color: palette.kicker,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      modernistNumber(available),
                      style: ModernistType.of(
                        size: 26,
                        weight: 900,
                        color: palette.ink,
                        tracking: -0.02,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _FilterChip(
                  selected: filter == null,
                  onTap: () => onFilter(null),
                  label: 'TODOS',
                ),
                for (final level in OperatorLevel.values) ...[
                  const SizedBox(width: 8),
                  _FilterChip(
                    selected: filter == level,
                    onTap: () => onFilter(level),
                    badge: ModernistColors.level(level),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.selected,
    required this.onTap,
    this.label,
    this.badge,
  });

  final bool selected;
  final VoidCallback onTap;
  final String? label;
  final Color? badge;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? palette.ink : null,
          border: Border.all(color: palette.ink, width: ModernistRule.base),
        ),
        child: label != null
            ? Text(
                label!,
                style: ModernistType.of(
                  size: 11,
                  weight: 800,
                  color: selected ? palette.bg : palette.ink,
                  tracking: 0.08,
                ),
              )
            // Cuadro de color como marcador de nivel. El export lo deja como
            // placeholder de la insignia que aún no existe.
            : Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: badge,
                  border: Border.all(
                    color: selected ? palette.bg : palette.ink,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Filas de la ruta ───────────────────────────────────────────────────────

/// Ancho del carril donde vive la línea vertical y los nodos.
const double _railWidth = 56;
const double _railLineLeft = 26;

class _LevelBanner extends StatelessWidget {
  const _LevelBanner({required this.level, required this.unlocked});

  final OperatorLevel level;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final floor = levelFloor(level);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(color: unlocked ? palette.ink : palette.outlineMuted),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 18, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: ModernistColors.level(level),
                      border: Border.all(color: palette.ink),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    level.displayName.toUpperCase(),
                    style: ModernistType.of(
                      size: 13,
                      weight: 900,
                      color: palette.ink,
                      tracking: 0.1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 2, color: palette.ink)),
                  const SizedBox(width: 10),
                  Text(
                    floor == 0 ? 'inicial' : '${modernistNumber(floor)} pts',
                    style: ModernistType.of(
                      size: 11,
                      weight: 700,
                      color: palette.kicker,
                      tracking: 0.06,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La línea vertical del carril, que atraviesa toda la fila.
class _Rail extends StatelessWidget {
  const _Rail({required this.color, this.child});

  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _railWidth,
      child: Stack(
        children: [
          Positioned(
            left: _railLineLeft,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: color),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({
    required this.premio,
    required this.state,
    required this.available,
    required this.onRedeem,
  });

  final Premio premio;
  final MilestoneState state;
  final int available;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final open = state == MilestoneState.open;
    final locked = state == MilestoneState.locked;
    final target = state == MilestoneState.target;

    final railColor = open ? palette.ink : palette.outlineMuted;
    final tier = premio.nivelMinimo ?? OperatorLevel.plata;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Rail(
            color: railColor,
            child: Positioned(
              left: 14,
              top: 28,
              child: Row(
                children: [
                  _Node(open: open, target: target),
                  // Conector corto del nodo a la tarjeta.
                  Container(width: 14, height: 2, color: railColor),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 20, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: target
                        ? ModernistColors.red
                        : open
                            ? palette.ink
                            : palette.outlineMuted,
                    width: target || open ? ModernistRule.base : 1,
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
                            premio.tipo.displayName.toUpperCase(),
                            style: modernistMono(
                              size: 9,
                              color: palette.kicker,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${modernistNumber(premio.costoPuntos)} pts',
                          style: ModernistType.of(
                            size: 19,
                            weight: 900,
                            color: open ? palette.ink : palette.disabled,
                            tracking: -0.02,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      premio.nombre,
                      style: ModernistType.of(
                        size: 16,
                        weight: 800,
                        color: open ? palette.ink : palette.kicker,
                        tracking: -0.01,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            switch (state) {
                              MilestoneState.locked =>
                                'Requiere nivel ${tier.displayName}',
                              MilestoneState.open => 'Puedes canjearlo',
                              _ => 'Te faltan '
                                  '${modernistNumber(
                                    premio.costoPuntos - available,
                                  )} pts',
                            },
                            style: ModernistType.of(
                              size: 11,
                              weight: 700,
                              color: open ? palette.ink : palette.kicker,
                              tracking: 0.06,
                            ),
                          ),
                        ),
                        if (open)
                          GestureDetector(
                            onTap: onRedeem,
                            child: Container(
                              constraints:
                                  const BoxConstraints(minHeight: 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              alignment: Alignment.center,
                              color: ModernistColors.red,
                              child: Text(
                                'CANJEAR',
                                style: ModernistType.of(
                                  size: 11,
                                  weight: 800,
                                  color: ModernistColors.onRed,
                                  tracking: 0.1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!open && !locked) ...[
                      const SizedBox(height: 2),
                      _SavingBar(
                        value: available / premio.costoPuntos,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Node extends StatefulWidget {
  const _Node({required this.open, required this.target});

  final bool open;
  final bool target;

  @override
  State<_Node> createState() => _NodeState();
}

class _NodeState extends State<_Node> with SingleTickerProviderStateMixin {
  // Se crea siempre, aunque solo lata en el nodo objetivo: si fuera `late`
  // perezoso, un nodo apagado nunca lo tocaría en `build` y `dispose` acabaría
  // construyéndolo al desmontar la pantalla.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.target) unawaited(_c.repeat());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    final node = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: widget.open ? palette.ink : palette.bg,
        border: Border.all(
          color: widget.target
              ? ModernistColors.red
              : widget.open
                  ? palette.ink
                  : palette.outlineMuted,
          width: ModernistRule.base,
        ),
      ),
    );

    if (!widget.target) return node;

    // nodePulse: un halo que crece y se desvanece alrededor del objetivo.
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: (1 - _c.value) * 0.5,
            child: Container(
              width: 28 + 18 * _c.value,
              height: 28 + 18 * _c.value,
              decoration: BoxDecoration(
                border: Border.all(color: ModernistColors.red),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: node,
    );
  }
}

class _SavingBar extends StatelessWidget {
  const _SavingBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return SizedBox(
      height: 6,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: palette.progressTrack),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                height: 6,
                child: ColoredBox(color: palette.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionMarker extends StatelessWidget {
  const _PositionMarker({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    const white = ModernistColors.onRed;

    return ColoredBox(
      color: ModernistColors.red,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _railWidth,
              child: Stack(
                children: [
                  const Positioned(
                    left: _railLineLeft,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: ColoredBox(color: white),
                  ),
                  Positioned(
                    left: 18,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _BlinkingMarker(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        'ESTÁS AQUÍ',
                        style: ModernistType.of(
                          size: 14,
                          weight: 900,
                          color: white,
                          tracking: 0.16,
                        ),
                      ),
                    ),
                    Text(
                      '${modernistNumber(balance)} pts',
                      style: ModernistType.of(
                        size: 13,
                        weight: 800,
                        color: white,
                        tracking: 0.06,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingMarker extends StatefulWidget {
  @override
  State<_BlinkingMarker> createState() => _BlinkingMarkerState();
}

class _BlinkingMarkerState extends State<_BlinkingMarker>
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

    return AnimatedBuilder(
      animation: curve,
      // markerBlink: opacidad 1 → .55
      builder: (context, child) => Opacity(
        opacity: 1 - 0.45 * curve.value,
        child: child,
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: ColoredBox(color: ModernistColors.onRed),
      ),
    );
  }
}

class _RouteFooter extends StatelessWidget {
  const _RouteFooter();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El riel muere aquí: un tramo corto y nada más. Va sin `Stack`
        // porque, sin hijos sin posicionar, no tendría altura que calcular.
        SizedBox(
          width: _railWidth,
          child: Padding(
            padding: const EdgeInsets.only(left: _railLineLeft),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 4,
                height: 22,
                child: ColoredBox(color: palette.outlineMuted),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 22, 20, 26),
            child: Text(
              'Cada viaje completado sin incidencias te acerca al siguiente '
              'hito de la ruta.',
              style: ModernistType.of(
                size: 12,
                weight: 600,
                color: palette.kicker,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
