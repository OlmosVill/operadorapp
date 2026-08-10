import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';

/// Pestañas del sistema Modernist.
///
/// Ojo que el export cambia «Config» por **Perfil**: mientras queden pantallas
/// sin migrar conviven esta barra y la `AppBottomNav` anterior, que sí lleva
/// Config. Ver pendientes en `docs/features/modernist-home.md`.
enum ModernistTab {
  inicio('INICIO', '/home'),
  viajes('VIAJES', '/trips'),
  premios('PREMIOS', '/rewards'),
  ranking('RANKING', '/ranking'),
  perfil('PERFIL', '/profile');

  const ModernistTab(this.label, this.route);

  final String label;
  final String route;
}

/// Las cuatro pestañas de siempre.
const List<ModernistTab> _defaultTabs = [
  ModernistTab.inicio,
  ModernistTab.viajes,
  ModernistTab.premios,
  ModernistTab.perfil,
];

/// Orden de las ramas del `StatefulShellRoute`, que es también el orden en que
/// se deslizan: la posición aquí decide si una pestaña entra por la derecha o
/// por la izquierda. Ranking no está porque se apila encima, no es una rama.
///
/// El router construye sus ramas a partir de esta lista, así que cambiar el
/// orden cambia el del deslizamiento sin tocar nada más.
const List<ModernistTab> modernistBranchTabs = _defaultTabs;

/// Lleva a [tab] respetando la animación de las pestañas.
///
/// Es lo que hay que usar desde cualquier pantalla que mande a otra pestaña
/// —el botón «ver todos» de Inicio, el atajo a Premios del perfil— en lugar de
/// un `context.go` suelto.
void goToModernistTab(BuildContext context, ModernistTab tab) {
  final branch = modernistBranchTabs.indexOf(tab);
  final shell = StatefulNavigationShell.maybeOf(context);

  // Sin shell a la vista estamos en una pantalla apilada encima (Ranking, un
  // detalle): navegar por ruta la cierra y deja la pestaña puesta.
  if (shell == null || branch < 0) {
    if (branch < 0) {
      unawaited(context.push(tab.route));
    } else {
      context.go(tab.route);
    }
    return;
  }

  shell.goBranch(branch);
}

/// Barra de pestañas del export. Reemplaza a la `NavigationBar` de Material en
/// las pantallas ya migradas.
class ModernistTabBar extends StatelessWidget {
  const ModernistTabBar({
    required this.current,
    this.tabs = _defaultTabs,
    this.ruled = false,
    super.key,
  });

  final ModernistTab current;

  /// Pestañas a mostrar. El export de «Ranking» cambia Premios por Ranking en
  /// esa pantalla, así que ahí se pasa un juego distinto.
  final List<ModernistTab> tabs;

  /// Dibuja la regla de 2 px sobre la barra. Va en `true` cuando lo de arriba
  /// no termina ya en una regla propia — el caso de «Inicio sin viaje», donde
  /// encima queda un área desplazable.
  final bool ruled;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.bg,
        border: ruled
            ? Border(
                top: BorderSide(
                  color: palette.ink,
                  width: ModernistRule.base,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: _Tab(
                tab: tab,
                selected: tab == current,
                onTap: () => _go(context, tab),
              ),
            ),
        ],
      ),
    );
  }

  void _go(BuildContext context, ModernistTab tab) {
    if (tab == current) return;
    goToModernistTab(context, tab);
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ModernistTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ModernistPalette.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 14),
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              // La regla de la pestaña activa sigue en rojo de marca en los dos
              // temas; lo único que cambia es el color de la etiqueta.
              color: selected ? ModernistColors.red : Colors.transparent,
              width: ModernistRule.tab,
            ),
          ),
        ),
        child: Text(
          tab.label,
          style: ModernistType.of(
            size: 11,
            weight: 800,
            color: selected ? palette.accentText : palette.kicker,
            tracking: 0.1,
          ),
        ),
      ),
    );
  }
}
