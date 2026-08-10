import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/core/router/modernist_tab_shell.dart';
import 'package:operadorapp/core/router/modernist_transitions.dart';
import 'package:operadorapp/features/auth/domain/entities/operator_session.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:operadorapp/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:operadorapp/features/auth/presentation/screens/login_screen.dart';
import 'package:operadorapp/features/points/presentation/screens/points_screen.dart';
import 'package:operadorapp/features/profile/presentation/screens/modernist/operator_profile_screen.dart';
import 'package:operadorapp/features/ranking/presentation/screens/modernist/ranking_screen.dart';
import 'package:operadorapp/features/rewards/presentation/screens/modernist/rewards_route_screen.dart';
import 'package:operadorapp/features/settings/presentation/screens/modernist/settings_screen.dart';
import 'package:operadorapp/features/trips/presentation/screens/home_screen.dart';
import 'package:operadorapp/features/trips/presentation/screens/modernist/trip_detail_screen.dart';
import 'package:operadorapp/features/trips/presentation/screens/modernist/trips_screen.dart';
import 'package:operadorapp/features/trips/presentation/widgets/modernist/modernist_tab_bar.dart';
import 'package:operadorapp/features/trucks/presentation/screens/truck_detail_screen.dart';
import 'package:operadorapp/features/trucks/presentation/screens/trucks_history_screen.dart';

// Notifier que escucha cambios de auth y notifica al router
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue<OperatorSession>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }
}

final routerNotifierProvider =
    ChangeNotifierProvider<_RouterNotifier>(_RouterNotifier.new);

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Una llave por pestaña: cada rama del shell mantiene su propio navegador y,
/// con él, el scroll y el estado de su pantalla.
final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = [
  for (final tab in modernistBranchTabs)
    GlobalKey<NavigatorState>(debugLabel: tab.name),
];

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/home',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState.value?.isAuthenticated ?? false;
      final isLoading = authState.isLoading;
      final isLoginRoute = state.matchedLocation.startsWith('/login');

      if (isLoading) return null; // esperar a que resuelva el stream
      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'forgot-password',
            builder: (_, __) => const ForgotPasswordScreen(),
          ),
        ],
      ),
      // Las cuatro pestañas de la barra Modernist viven en un shell con una
      // rama cada una. No dibuja nada alrededor —cada pantalla trae su propia
      // barra—: lo único que aporta es conservar el estado de cada pestaña y
      // animar el paso de una a otra. Ver `ModernistTabShell`.
      StatefulShellRoute(
        pageBuilder: (context, state, shell) => modernistPage(
          key: state.pageKey,
          child: shell,
        ),
        navigatorContainerBuilder: (context, shell, children) =>
            ModernistTabShell(shell: shell, branches: children),
        branches: [
          StatefulShellBranch(
            navigatorKey: _tabNavigatorKeys[0],
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          // El resto se precarga: para que el arrastre muestre la pestaña
          // vecina moviéndose de verdad, su navegador tiene que existir antes
          // de que el dedo toque la pantalla. Sin esto la primera vez se
          // arrastraría contra un hueco en blanco.
          StatefulShellBranch(
            navigatorKey: _tabNavigatorKeys[1],
            preload: true,
            routes: [
              GoRoute(
                path: '/trips',
                builder: (_, __) => const ModernistTripsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tabNavigatorKeys[2],
            preload: true,
            routes: [
              GoRoute(
                path: '/rewards',
                builder: (_, __) => const RewardsRouteScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tabNavigatorKeys[3],
            preload: true,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const OperatorProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Fuera del shell: se apilan encima de las pestañas y entran desde la
      // derecha.
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => modernistPage(
          key: state.pageKey,
          child: const ModernistSettingsScreen(),
        ),
      ),
      // El export «Premios Ruta» fusiona catálogo y roadmap en una vista, así
      // que `/rewards/catalog` apunta a la misma pantalla mientras quedan
      // enlaces viejos apuntando ahí.
      GoRoute(
        path: '/rewards/catalog',
        pageBuilder: (_, state) => modernistPage(
          key: state.pageKey,
          child: const RewardsRouteScreen(),
        ),
      ),
      GoRoute(
        path: '/points',
        pageBuilder: (_, state) => modernistPage(
          key: state.pageKey,
          child: const PointsScreen(),
        ),
      ),
      GoRoute(
        path: '/ranking',
        pageBuilder: (_, state) => modernistPage(
          key: state.pageKey,
          child: const ModernistRankingScreen(),
        ),
      ),
      GoRoute(
        path: '/trips/:id',
        pageBuilder: (_, state) => modernistPage(
          key: state.pageKey,
          child: ModernistTripDetailScreen(
            tripId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/trucks',
        pageBuilder: (_, state) => modernistPage(
          key: state.pageKey,
          child: const TrucksHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/trucks/:id',
        pageBuilder: (_, state) => modernistPage(
          key: state.pageKey,
          child: TruckDetailScreen(
            tractoId: state.pathParameters['id']!,
          ),
        ),
      ),
    ],
  );
});
