import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/core/router/modernist_tab_shell.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/modernist_tab_bar.dart';

/// Pantalla de mentira: sólo necesita ocupar la rama y ser localizable.
class _Page extends StatelessWidget {
  const _Page(this.label, this.tab);

  final String label;
  final ModernistTab tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey(label),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            key: ValueKey('boton-$label'),
            onPressed: () => ModernistTabShellHarness.taps.add(label),
            child: Text(label),
          ),
          const Spacer(),
          // La barra de verdad: así se comprueba que un toque en una pestaña
          // encuentra el shell y cambia de rama con su animación.
          ModernistTabBar(current: tab),
        ],
      ),
    );
  }
}

/// Bolsa para comprobar quién recibió los toques.
abstract final class ModernistTabShellHarness {
  static final taps = <String>[];
}

/// Una etiqueta por rama, en el mismo orden que las pestañas de verdad.
const _labels = ['A', 'B', 'C', 'D'];

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/a',
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => shell,
        navigatorContainerBuilder: (context, shell, children) =>
            ModernistTabShell(shell: shell, branches: children),
        branches: [
          for (final (index, label) in _labels.indexed)
            StatefulShellBranch(
              preload: true,
              routes: [
                GoRoute(
                  path: '/${label.toLowerCase()}',
                  builder: (_, __) => _Page(label, modernistBranchTabs[index]),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

Future<GoRouter> _pumpShell(WidgetTester tester) async {
  final router = _buildRouter();
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  // La precarga de las ramas ocurre después del primer frame.
  await tester.pumpAndSettle();
  return router;
}

/// Posición horizontal de una pestaña, incluso si está fuera de pantalla.
double _xOf(WidgetTester tester, String label) =>
    tester.getTopLeft(find.byKey(ValueKey(label), skipOffstage: false)).dx;

void main() {
  setUp(ModernistTabShellHarness.taps.clear);

  testWidgets('la pestaña siguiente entra desde la derecha', (tester) async {
    final router = await _pumpShell(tester);
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    router.go('/b');
    await tester.pump();
    // Un frame después de arrancar, B todavía viene en camino desde la derecha
    // y A ya empezó a salir por la izquierda.
    await tester.pump(const Duration(milliseconds: 60));

    expect(_xOf(tester, 'B'), greaterThan(0));
    expect(_xOf(tester, 'B'), lessThan(width));
    expect(_xOf(tester, 'A'), lessThan(0));

    await tester.pumpAndSettle();
    expect(_xOf(tester, 'B'), 0);
  });

  testWidgets('volver a la anterior la trae desde la izquierda',
      (tester) async {
    final router = await _pumpShell(tester);

    router.go('/b');
    await tester.pumpAndSettle();

    router.go('/a');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(_xOf(tester, 'A'), lessThan(0));
    expect(_xOf(tester, 'B'), greaterThan(0));

    await tester.pumpAndSettle();
    expect(_xOf(tester, 'A'), 0);
  });

  testWidgets('arrastrar desde el borde derecho pasa a la siguiente',
      (tester) async {
    await _pumpShell(tester);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;

    final gesture = await tester.startGesture(
      Offset(size.width - 8, size.height / 2),
    );
    // A media pantalla ya se ven las dos moviéndose con el dedo.
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    expect(_xOf(tester, 'A'), -200);
    expect(_xOf(tester, 'B'), size.width - 200);

    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_xOf(tester, 'B'), 0);
  });

  testWidgets('arrastrar desde el borde izquierdo vuelve a la anterior',
      (tester) async {
    final router = await _pumpShell(tester);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;

    router.go('/b');
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(Offset(8, size.height / 2));
    await gesture.moveBy(const Offset(300, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_xOf(tester, 'A'), 0);
  });

  testWidgets('un arrastre corto se devuelve a su sitio', (tester) async {
    await _pumpShell(tester);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;

    final gesture = await tester.startGesture(
      Offset(size.width - 8, size.height / 2),
    );
    // Menos del 28 % del ancho y sin impulso: no alcanza para cambiar.
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_xOf(tester, 'A'), 0);
  });

  testWidgets('tocar una pestaña de la barra la desliza desde su lado',
      (tester) async {
    await _pumpShell(tester);
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;

    await tester.tap(find.text(ModernistTab.premios.label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // Premios está dos lugares a la derecha de Inicio: entra por ahí.
    expect(_xOf(tester, 'C'), greaterThan(0));
    expect(_xOf(tester, 'C'), lessThan(width));

    await tester.pumpAndSettle();
    expect(_xOf(tester, 'C'), 0);

    // Y de vuelta a Inicio, entrando por la izquierda.
    await tester.tap(find.text(ModernistTab.inicio.label));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_xOf(tester, 'A'), lessThan(0));

    await tester.pumpAndSettle();
    expect(_xOf(tester, 'A'), 0);
  });

  testWidgets('la pestaña entrante no recibe toques hasta que es la activa',
      (tester) async {
    final router = await _pumpShell(tester);

    router.go('/b');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // Con la transición a medias, B ya está en pantalla pero es A quien manda:
    // un toque en el área de B no debe activarlo.
    await tester.tap(
      find.byKey(const ValueKey('boton-B'), skipOffstage: false),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(ModernistTabShellHarness.taps, isEmpty);

    await tester.tap(find.byKey(const ValueKey('boton-B')));
    await tester.pump();
    expect(ModernistTabShellHarness.taps, ['B']);
  });
}
