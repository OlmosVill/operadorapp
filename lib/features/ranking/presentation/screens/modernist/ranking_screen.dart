import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';
import 'package:operadorapp/features/ranking/presentation/providers/ranking_provider.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/modernist_tab_bar.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

/// Tabla de posiciones entre operadores, implementando el export «Ranking».
///
/// Sustituye a la `RankingScreen` anterior. El podio va con los tres primeros
/// en orden 2·1·3, la tabla lista al resto y una barra fija abajo resume el
/// lugar propio.
class ModernistRankingScreen extends ConsumerWidget {
  const ModernistRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ModernistPalette.of(context);
    final entriesAsync = ref.watch(rankingProvider);
    final mine = ref.watch(myRankingEntryProvider);
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
              _RankingHeader(total: entriesAsync.value?.length ?? 0),
              Expanded(
                child: entriesAsync.when(
                  loading: () =>
                      const AppLoadingWidget(message: 'Cargando ranking...'),
                  error: (_, __) => const _RankingUnavailable(),
                  data: (entries) => entries.isEmpty
                      ? const _RankingUnavailable()
                      : _RankingList(entries: entries, mine: mine),
                ),
              ),
              _MyPlaceBar(entry: mine),
              const ModernistTabBar(
                current: ModernistTab.ranking,
                // El export cambia Premios por Ranking en esta pantalla.
                tabs: [
                  ModernistTab.inicio,
                  ModernistTab.viajes,
                  ModernistTab.ranking,
                  ModernistTab.perfil,
                ],
                ruled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Paleta propia del ranking ──────────────────────────────────────────────

/// Colores que solo usa esta pantalla: el verde y el rojo del movimiento de
/// lugares no son los del resto del sistema, y la fila propia tiene su tinte.
/// El verde y el rojo del movimiento viven en [ModernistPalette] porque el
/// popup de resumen los usa igual; lo de aquí es solo de esta tabla.
class _RankPalette {
  const _RankPalette({
    required this.flat,
    required this.selfRowBg,
    required this.position,
    required this.avatarBg,
    required this.avatarFg,
  });

  static _RankPalette of(ModernistPalette palette) =>
      palette.isDark ? _rankDark : _rankLight;

  final Color flat;
  final Color selfRowBg;
  final Color position;
  final Color avatarBg;
  final Color avatarFg;
}

const _rankLight = _RankPalette(
  flat: Color(0xFF9B9797),
  selfRowBg: Color(0xFFEDE4E4),
  position: Color(0xFF7D7979),
  avatarBg: Color(0xFFD7D3D3),
  avatarFg: Color(0xFF605D5D),
);

const _rankDark = _RankPalette(
  flat: Color(0xFF9B9797),
  selfRowBg: Color(0xFF3D2C2C),
  position: Color(0xFFA5A1A1),
  avatarBg: Color(0xFF443F3F),
  avatarFg: Color(0xFFBDB9B9),
);

Color _deltaColor(
  RankingEntry entry,
  ModernistPalette palette,
  _RankPalette rank,
) =>
    switch (entry.trend) {
      RankingTrend.subio => palette.rankUp,
      RankingTrend.bajo => palette.rankDown,
      _ => rank.flat,
    };

/// «▲ 2» · «▼ 1» · «—» · «nuevo».
///
/// El triángulo va pintado y no como carácter: Archivo no trae ▲ ni ▼, así
/// que en el dispositivo dependería del respaldo del sistema y en los goldens
/// saldría como un cuadro vacío.
class _DeltaLabel extends StatelessWidget {
  const _DeltaLabel({
    required this.entry,
    required this.size,
    this.color,
    this.alignEnd = false,
  });

  final RankingEntry entry;
  final double size;

  /// Fuerza el color; si es null se usa el del movimiento.
  final Color? color;

  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final tint = color ?? _deltaColor(entry, palette, _RankPalette.of(palette));
    final style = ModernistType.of(
      size: size,
      weight: 800,
      color: tint,
      tracking: 0.02,
    );

    final label = switch (entry.trend) {
      RankingTrend.nuevo => 'nuevo',
      RankingTrend.igual => '—',
      _ => '${entry.lugaresMovidosAbs}',
    };

    final arrow = switch (entry.trend) {
      RankingTrend.subio => true,
      RankingTrend.bajo => false,
      _ => null,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (arrow != null) ...[
          CustomPaint(
            size: Size(size * 0.62, size * 0.55),
            painter: _TrianglePainter(up: arrow, color: tint),
          ),
          SizedBox(width: size * 0.3),
        ],
        Text(label, style: style),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.up, required this.color});

  final bool up;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.up != up || old.color != color;
}

/// La ★ de la calificación, por el mismo motivo que los triángulos: Archivo no
/// la trae y no queremos depender del respaldo del sistema.
class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final path = Path();

    for (var i = 0; i < 10; i++) {
      // Alterna punta y valle cada 36°, arrancando desde arriba.
      final r = i.isEven ? radius : radius * 0.42;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

// ─── Cabecera ───────────────────────────────────────────────────────────────

class _RankingHeader extends ConsumerWidget {
  const _RankingHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ModernistPalette.of(context);
    final periodo = ref.watch(rankingPeriodoProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FLOTA · $total ${total == 1 ? 'OPERADOR' : 'OPERADORES'}',
            style: ModernistType.kicker(
              size: 11,
              tracking: 0.14,
              color: palette.kicker,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'RANKING',
            style: ModernistType.of(
              size: 31,
              weight: 900,
              color: palette.ink,
              tracking: -0.03,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: palette.ink, width: ModernistRule.base),
            ),
            child: Row(
              children: [
                for (final option in RankingPeriodo.values)
                  Expanded(
                    child: _PeriodButton(
                      periodo: option,
                      selected: option == periodo,
                      onTap: () => ref
                          .read(rankingPeriodoProvider.notifier)
                          .state = option,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            // Comillas simples dentro del patrón: sin ellas, la «e» de «de»
            // se leería como el especificador de día de la semana.
            'Corte del ${DateFormat("d 'de' MMMM", 'es_MX').format(
              DateTime.now(),
            )} · el movimiento compara contra el corte anterior',
            style: ModernistType.of(
              size: 11,
              weight: 600,
              color: palette.kicker,
              tracking: 0.04,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.periodo,
    required this.selected,
    required this.onTap,
  });

  final RankingPeriodo periodo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        alignment: Alignment.centerLeft,
        color: selected ? palette.ink : null,
        child: Text(
          periodo.displayName.toUpperCase(),
          style: ModernistType.of(
            size: 11,
            weight: 800,
            color: selected ? palette.bg : palette.ink,
            tracking: 0.12,
          ),
        ),
      ),
    );
  }
}

// ─── Podio y tabla ──────────────────────────────────────────────────────────

class _RankingList extends StatelessWidget {
  const _RankingList({required this.entries, required this.mine});

  final List<RankingEntry> entries;
  final RankingEntry? mine;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final podium = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (podium.isNotEmpty) _Podium(entries: podium),
        const _TableHead(),
        for (final entry in rest)
          _RankingRow(
            entry: entry,
            isMine: entry.operadorId == mine?.operadorId,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Text(
            'Las posiciones las calcula el servidor una vez al día. Los puntos '
            'negativos por incidencias no cuentan aquí: el ranking suma solo '
            'lo ganado.',
            style: ModernistType.of(
              size: 11,
              weight: 600,
              color: palette.kicker,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<RankingEntry> entries;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    // El podio se lee 2 · 1 · 3, con el campeón al centro.
    final ordered = [
      if (entries.length > 1) entries[1],
      entries[0],
      if (entries.length > 2) entries[2],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.ink, width: ModernistRule.base),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, entry) in ordered.indexed) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(child: _PodiumStep(entry: entry)),
          ],
        ],
      ),
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    final height = switch (entry.posicion) {
      1 => 108.0,
      2 => 84.0,
      _ => 66.0,
    };
    // El escalón se colorea por lugar, y el texto contra su propio fondo: el
    // segundo va sobre tinta, que en oscuro es claro — con blanco fijo
    // desaparecería.
    final (blockBg, blockFg) = switch (entry.posicion) {
      1 => (ModernistColors.red, ModernistColors.onRed),
      2 => (palette.ink, palette.bg),
      _ => (null, palette.ink),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: ModernistColors.level(entry.nivel),
            border: Border.all(color: palette.ink, width: ModernistRule.base),
          ),
        ),
        Text(
          entry.nombreCompleto.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ModernistType.of(
            size: 14,
            weight: 800,
            color: palette.ink,
            tracking: -0.01,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        _DeltaLabel(entry: entry, size: 11),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: blockBg,
            border: Border(
              top: BorderSide(color: palette.ink, width: ModernistRule.base),
              left: BorderSide(color: palette.ink, width: ModernistRule.base),
              right: BorderSide(color: palette.ink, width: ModernistRule.base),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.posicion}',
                style: ModernistType.of(
                  size: 34,
                  weight: 900,
                  color: blockFg,
                  tracking: -0.04,
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${modernistNumber(entry.puntos)} PTS',
                style: ModernistType.of(
                  size: 11,
                  weight: 700,
                  color: blockFg,
                  tracking: 0.06,
                  // El bloque más bajo mide 66 px justos: sin fijar el
                  // interlineado como el del navegador, Archivo se pasa.
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Anchos de la rejilla: lugar · avatar · operador · puntos · movimiento.
const double _colPlace = 34;
const double _colAvatar = 28;
const double _colDelta = 40;
const double _colGap = 7;

class _TableHead extends StatelessWidget {
  const _TableHead();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final style = ModernistType.of(
      size: 10,
      weight: 800,
      color: palette.kicker,
      tracking: 0.08,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.rowDivider)),
      ),
      child: Row(
        children: [
          // La columna mide 34 px justos: el rótulo se sale un poco sobre el
          // hueco del avatar, igual que en la rejilla del export.
          SizedBox(
            width: _colPlace,
            child: Text(
              'LUGAR',
              softWrap: false,
              overflow: TextOverflow.visible,
              style: style,
            ),
          ),
          const SizedBox(width: _colGap + _colAvatar + _colGap),
          Expanded(child: Text('OPERADOR', style: style)),
          const SizedBox(width: _colGap),
          Text('PTS', style: style),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _colDelta,
            child: Text('CAM.', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry, required this.isMine});

  final RankingEntry entry;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);
    final rank = _RankPalette.of(palette);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? rank.selfRowBg : null,
        border: Border(
          bottom: BorderSide(color: palette.rowDivider.withValues(alpha: 0.22)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _colPlace,
            child: Text(
              '${entry.posicion}',
              style: ModernistType.of(
                size: 19,
                weight: 900,
                color: isMine ? palette.accentText : rank.position,
                tracking: -0.03,
              ),
            ),
          ),
          const SizedBox(width: _colGap),
          Container(
            width: _colAvatar,
            height: _colAvatar,
            padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
            alignment: Alignment.bottomLeft,
            color: isMine ? ModernistColors.red : rank.avatarBg,
            child: Text(
              entry.iniciales,
              style: ModernistType.of(
                size: 11,
                weight: 900,
                color: isMine ? ModernistColors.onRed : rank.avatarFg,
                tracking: -0.01,
              ),
            ),
          ),
          const SizedBox(width: _colGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMine
                      ? '${entry.nombreCompleto} (tú)'
                      : entry.nombreCompleto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ModernistType.of(
                    size: 14,
                    weight: 700,
                    color: isMine ? palette.accentText : palette.ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      color: ModernistColors.level(entry.nivel),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.nivel.displayName.toUpperCase(),
                      style: ModernistType.of(
                        size: 10,
                        weight: 800,
                        color: palette.kicker,
                        tracking: 0.08,
                      ),
                    ),
                    if (entry.calificacion case final score?) ...[
                      const SizedBox(width: 6),
                      Text(
                        score.toStringAsFixed(1),
                        style: ModernistType.of(
                          size: 10,
                          weight: 700,
                          color: palette.disabled,
                          tracking: 0.04,
                        ),
                      ),
                      const SizedBox(width: 2),
                      CustomPaint(
                        size: const Size(9, 9),
                        painter: _StarPainter(color: palette.disabled),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: _colGap),
          Text(
            modernistNumber(entry.puntos),
            style: ModernistType.of(
              size: 15,
              weight: 800,
              color: palette.ink,
              tracking: -0.02,
            ),
          ),
          const SizedBox(width: _colGap),
          SizedBox(
            width: _colDelta,
            child: _DeltaLabel(entry: entry, size: 11, alignEnd: true),
          ),
        ],
      ),
    );
  }
}

// ─── Barra «Tu lugar» ───────────────────────────────────────────────────────

class _MyPlaceBar extends StatelessWidget {
  const _MyPlaceBar({required this.entry});

  final RankingEntry? entry;

  @override
  Widget build(BuildContext context) {
    const white = ModernistColors.onRed;

    return Container(
      width: double.infinity,
      color: ModernistColors.red,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Opacity(
            opacity: 0.85,
            child: Text(
              'TU LUGAR',
              style: ModernistType.of(
                size: 10,
                weight: 800,
                color: white,
                tracking: 0.14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry == null ? '—' : '#${entry!.posicion}',
            style: ModernistType.of(
              size: 26,
              weight: 900,
              color: white,
              tracking: -0.03,
              height: 1,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _note(entry),
              style: ModernistType.of(
                size: 12,
                weight: 600,
                color: white,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (entry case final mine?)
            // Sobre el rojo de marca el movimiento va en blanco: el verde y
            // el rojo del delta no contrastarían.
            _DeltaLabel(entry: mine, size: 13, color: white)
          else
            Text(
              '—',
              style: ModernistType.of(
                size: 13,
                weight: 800,
                color: white,
                tracking: 0.04,
              ),
            ),
        ],
      ),
    );
  }

  static String _note(RankingEntry? entry) {
    if (entry == null) return 'Todavía no apareces en el corte';

    final moved = entry.lugaresMovidosAbs;
    final places = moved == 1 ? 'lugar' : 'lugares';

    return switch (entry.trend) {
      RankingTrend.nuevo => 'Primer corte con tu nombre',
      RankingTrend.subio => 'Subiste $moved $places desde el corte anterior',
      RankingTrend.bajo => 'Bajaste $moved $places desde el corte anterior',
      RankingTrend.igual => 'Mantuviste tu lugar',
    };
  }
}

class _RankingUnavailable extends StatelessWidget {
  const _RankingUnavailable();

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Todavía no hay un corte publicado. El servidor calcula las posiciones '
        'una vez al día.',
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
