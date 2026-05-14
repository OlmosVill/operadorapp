import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/features/auth/domain/entities/operator_session.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:operadorapp/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:operadorapp/features/auth/presentation/screens/login_screen.dart';
import 'package:operadorapp/features/points/presentation/screens/points_screen.dart';
import 'package:operadorapp/features/profile/presentation/screens/profile_screen.dart';
import 'package:operadorapp/features/rewards/presentation/screens/rewards_roadmap_screen.dart';
import 'package:operadorapp/features/rewards/presentation/screens/rewards_screen.dart';
import 'package:operadorapp/features/settings/presentation/screens/settings_screen.dart';
import 'package:operadorapp/features/trips/presentation/screens/home_screen.dart';
import 'package:operadorapp/features/trips/presentation/screens/trip_detail_screen.dart';
import 'package:operadorapp/features/trips/presentation/screens/trips_list_screen.dart';

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

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
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
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/trips',
            builder: (_, __) => const TripsListScreen(),
          ),
          GoRoute(
            path: '/rewards',
            builder: (_, __) => const RewardsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/rewards/roadmap',
        builder: (_, __) => const RewardsRoadmapScreen(),
      ),
      GoRoute(
        path: '/points',
        builder: (_, __) => const PointsScreen(),
      ),
      GoRoute(
        path: '/trips/:id',
        builder: (_, state) => TripDetailScreen(
          tripId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    final currentIndex = switch (true) {
      _ when location.startsWith('/trips') => 1,
      _ when location.startsWith('/rewards') => 2,
      _ when location.startsWith('/settings') => 3,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/trips');
            case 2:
              context.go('/rewards');
            case 3:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Viajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.redeem_outlined),
            selectedIcon: Icon(Icons.redeem),
            label: 'Premios',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}
