import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/providers/app_refresh.dart';
import 'package:operadorapp/core/theme/modernist/modernist_tokens.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/summary/presentation/providers/return_summary_provider.dart';
import 'package:operadorapp/features/summary/presentation/widgets/modernist/return_summary_dialog.dart';
import 'package:operadorapp/features/trips/presentation/providers/home_provider.dart';
import 'package:operadorapp/features/trips/presentation/screens/modernist/active_trip_home_screen.dart';
import 'package:operadorapp/features/trips/presentation/screens/modernist/idle_home_screen.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

/// Punto de entrada del inicio.
///
/// No dibuja nada propio: elige la pantalla Modernist que toca según
/// `HomeState` y se encarga del popup de resumen de regreso.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  /// Evita reprogramar el callback una vez que el resumen ya se resolvió.
  ///
  /// Se rearma al volver del segundo plano: cada regreso es una oportunidad
  /// nueva de contar lo que pasó, no solo el arranque en frío.
  bool _summaryHandled = false;

  /// El popup está en pantalla. Un `resumed` mientras tanto —el operador se
  /// salió y volvió con el resumen abierto— no debe apilar un segundo popup.
  bool _summaryVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    updateHomLastSeen(ref);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // Al irse a segundo plano se fija el punto de comparación del próximo
      // resumen: lo que el operador ya vio no debe volver a anunciarse.
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(saveReturnSnapshot(ref));
      case AppLifecycleState.resumed:
        unawaited(_handleResume());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Regreso desde segundo plano.
  ///
  /// Mientras la app estuvo fuera de foco pudieron cerrarse viajes, y nada de
  /// eso llega solo: los streams de Drift siguen abiertos —así que ningún
  /// repositorio vuelve a sincronizar— y el resumen ya quedó marcado como
  /// mostrado en esta sesión. Sin esto había que matar la app y volver a
  /// abrirla para que apareciera el popup.
  Future<void> _handleResume() async {
    if (_summaryVisible) return;

    // El snapshot escrito al salir pasa a ser el punto de comparación: se
    // compara contra lo último que el operador vio, no contra el arranque.
    ref.read(returnSnapshotStoreProvider).rotate();
    _summaryHandled = false;
    ref.read(returnSummaryShownProvider.notifier).state = false;

    await refreshFromServer(ref);
    if (!mounted) return;

    // La sincronización pudo no cambiar nada observable —los puntos ya
    // estaban en Drift—, así que no basta con esperar el rebuild del stream.
    ref.invalidate(returnSummaryProvider);
    await _maybeShowSummary();
  }

  /// Programa la revisión del resumen para DESPUÉS del frame.
  ///
  /// Nada de esto puede correr dentro de `build`: marcar el resumen como visto
  /// escribe en un provider, y Riverpod aborta el build con una excepción si se
  /// modifica estado mientras se construye el árbol.
  void _scheduleSummaryCheck() {
    if (_summaryHandled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeShowSummary());
    });
  }

  Future<void> _maybeShowSummary() async {
    if (!mounted || _summaryHandled || _summaryVisible) return;

    if (ref.read(returnSummaryShownProvider)) {
      _summaryHandled = true;
      return;
    }

    // Viajes y ranking llegan asíncronos: si todavía no hay resumen se
    // reintenta en el próximo build, sin marcar nada.
    final summary = ref.read(returnSummaryProvider);
    if (summary == null) return;

    _summaryHandled = true;
    _summaryVisible = true;
    ref.read(returnSummaryShownProvider.notifier).state = true;

    try {
      await showReturnSummaryDialog(context, summary);
    } finally {
      _summaryVisible = false;
    }
    if (!mounted) return;
    await saveReturnSnapshot(ref);
    // Lo recién mostrado ya es el pasado: si el operador vuelve a salir y
    // entrar sin que pase nada nuevo, no debe repetirse el mismo resumen.
    ref.read(returnSnapshotStoreProvider).rotate();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final homeState = ref.watch(homeStateProvider);

    // Se reprograma en cada build porque los viajes y el ranking llegan de
    // forma asíncrona: el resumen sólo está completo cuando Drift ya emitió.
    _scheduleSummaryCheck();

    if (profile == null) {
      return Scaffold(
        backgroundColor: ModernistPalette.of(context).bg,
        body: const AppLoadingWidget(message: 'Cargando...'),
      );
    }

    return switch (homeState) {
      HomeStateActiveTrip(:final trip) =>
        ActiveTripHomeScreen(profile: profile, trip: trip),
      // El tablero del mes y el regreso comparten el export «Inicio Sin Viaje».
      _ => IdleHomeScreen(profile: profile, homeState: homeState),
    };
  }
}
