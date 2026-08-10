import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Contenedor de las ramas del `StatefulShellRoute`.
///
/// Sustituye al `IndexedStack` que trae go_router por defecto, que cambia de
/// pestaña de golpe. Aquí las ramas se colocan una junto a otra en una tira
/// horizontal y lo que se anima es la posición de la tira: al pasar de Inicio a
/// Viajes la pantalla nueva entra desde la derecha, y al volver entra desde la
/// izquierda. El movimiento dice de dónde sale cada pestaña.
///
/// La misma tira es la que sigue al dedo: un arrastre que empiece en una franja
/// del borde ([edgeWidth]) mueve las dos pantallas en tiempo real y al soltar
/// remata hacia la pestaña que quedó más cerca.
class ModernistTabShell extends StatefulWidget {
  const ModernistTabShell({
    required this.shell,
    required this.branches,
    super.key,
  });

  /// Ancho de las franjas de los bordes que escuchan el arrastre.
  ///
  /// En Android los primeros ~20 dp de cada lado se los queda el gesto de
  /// «atrás» del sistema, así que la franja tiene que ser cómodamente más ancha
  /// para que quede zona útil.
  static const double edgeWidth = 48;

  /// Fracción de pantalla que hay que arrastrar para que el gesto cambie de
  /// pestaña al soltar sin necesidad de impulso.
  static const double _commitFraction = 0.28;

  /// Velocidad (px/s) a partir de la cual el impulso decide por sí solo.
  static const double _flingVelocity = 320;

  final StatefulNavigationShell shell;

  /// Los navegadores de cada rama, en el orden de `branches` del shell.
  final List<Widget> branches;

  @override
  State<ModernistTabShell> createState() => _ModernistTabShellState();
}

class _ModernistTabShellState extends State<ModernistTabShell>
    with SingleTickerProviderStateMixin {
  /// Posición de la tira, en unidades de pestaña: 1.5 es justo entre la segunda
  /// y la tercera. Sin acotar porque el valor no es un 0..1.
  late final AnimationController _position;

  /// Pestaña a la que apunta la animación en curso. Sirve para no relanzarla
  /// cuando el rebuild del shell trae el índice que ya se está persiguiendo.
  late int _target;

  /// Pestaña desde la que arrancó el arrastre actual.
  int _dragOrigin = 0;
  bool _dragging = false;

  int get _lastIndex => widget.branches.length - 1;

  @override
  void initState() {
    super.initState();
    _target = widget.shell.currentIndex;
    _position = AnimationController.unbounded(
      vsync: this,
      value: _target.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant ModernistTabShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El índice cambia por un toque en la barra o por un `context.go` desde
    // cualquier pantalla; el arrastre ya lanzó su propia animación antes de
    // llamar a `goBranch`.
    if (!_dragging && widget.shell.currentIndex != _target) {
      _settle(widget.shell.currentIndex);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  /// Anima la tira hasta [index]. La duración crece con la distancia para que
  /// soltar a medio camino no dé un tirón seco.
  void _settle(int index) {
    _target = index;

    // De Inicio a Premios hay dos pestañas de por medio: recorrerlas todas
    // dejaría pasar Viajes como un borrón. La tira salta a un ancho de la
    // pestaña destino, del lado que le toca, y desde ahí sí se desliza. Se
    // mantiene el sentido —viene de la derecha— sin el manchón.
    final distance = index - _position.value;
    if (distance.abs() > 1) {
      _position.value = index + (distance > 0 ? -1 : 1).toDouble();
    }
    final remaining = (index - _position.value).abs();
    unawaited(
      _position.animateTo(
        index.toDouble(),
        duration: Duration(milliseconds: (150 + 190 * remaining).round()),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    _position.stop();
    _dragging = true;
    _dragOrigin = _position.value.round().clamp(0, _lastIndex);
  }

  /// El gesto se lo llevó otro reconocedor: la tira vuelve a donde estaba.
  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _settle(widget.shell.currentIndex);
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (width == 0) return;
    // Arrastrar hacia la izquierda (delta negativo) trae la pestaña siguiente,
    // igual que empujar una tira de papel.
    final next = _position.value - details.primaryDelta! / width;
    _position.value = next.clamp(0.0, _lastIndex.toDouble());
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final travelled = _position.value - _dragOrigin;

    var target = _dragOrigin;
    if (velocity.abs() >= ModernistTabShell._flingVelocity) {
      target += velocity < 0 ? 1 : -1;
    } else if (travelled.abs() >= ModernistTabShell._commitFraction) {
      target += travelled > 0 ? 1 : -1;
    }
    target = target.clamp(0, _lastIndex);

    // Primero la animación y luego el cambio de rama: `goBranch` provoca un
    // rebuild y `didUpdateWidget` no debe relanzar nada.
    _settle(target);
    if (target != widget.shell.currentIndex) {
      widget.shell.goBranch(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return AnimatedBuilder(
          animation: _position,
          builder: (context, _) {
            return Stack(
              children: [
                for (var i = 0; i < widget.branches.length; i++)
                  _branchSlot(i, width),
                _edgeGrip(width: width, left: true),
                _edgeGrip(width: width, left: false),
              ],
            );
          },
        );
      },
    );
  }

  /// Una rama colocada en la tira. Las que quedan fuera de la pantalla van en
  /// `Offstage` para no pintarlas ni medirlas, pero siguen en el árbol: es lo
  /// que conserva el scroll y el estado de cada pestaña.
  Widget _branchSlot(int index, double width) {
    final offset = index - _position.value;
    final visible = offset.abs() < 1;
    final isCurrent = index == widget.shell.currentIndex;

    return Positioned.fill(
      child: Offstage(
        offstage: !visible,
        child: TickerMode(
          enabled: visible,
          child: IgnorePointer(
            // Durante el movimiento sólo la pestaña activa recibe toques; si
            // no, un dedo apoyado a media transición pulsaría la entrante.
            ignoring: !isCurrent,
            child: Transform.translate(
              offset: Offset(offset * width, 0),
              child: widget.branches[index],
            ),
          ),
        ),
      ),
    );
  }

  /// Franja del borde que escucha el arrastre.
  ///
  /// Es translúcida a propósito: no debe robarle los toques al contenido que
  /// tiene debajo, sólo competir en la arena de gestos cuando el movimiento es
  /// horizontal. Un scroll vertical de la lista sigue ganando.
  Widget _edgeGrip({required double width, required bool left}) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      width: math.min(ModernistTabShell.edgeWidth, width),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, width),
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: _onDragCancel,
      ),
    );
  }
}
