import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Transición de las pantallas que se apilan sobre las pestañas —detalle de
/// viaje, tractos, ranking, ajustes.
///
/// Entran desde la derecha y empujan a la de abajo un cuarto de pantalla hacia
/// la izquierda: el mismo lenguaje que el deslizamiento entre pestañas, así que
/// siempre se ve de dónde sale y a dónde vuelve cada pantalla. La de Material
/// por defecto en Android sube desde abajo con un desvanecido y no dice nada
/// del recorrido.
CustomTransitionPage<void> modernistPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final enter = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final leave = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(enter),
        child: SlideTransition(
          // La segunda animación es la de esta misma página cuando otra se le
          // pone encima.
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.25, 0),
          ).animate(leave),
          child: child,
        ),
      );
    },
  );
}
