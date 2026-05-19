import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:operadorapp/core/theme/app_colors.dart';
import 'package:operadorapp/features/profile/domain/entities/operator_profile.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/profile/presentation/widgets/level_badge.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/home_provider.dart';
import 'package:operadorapp/features/trips/presentation/widgets/active_trip_card.dart';
import 'package:operadorapp/features/trips/presentation/widgets/trip_card.dart';
import 'package:operadorapp/shared/widgets/app_loading_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    updateHomLastSeen(ref);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final homeState = ref.watch(homeStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OperadorApp'),
        actions: [
          profileAsync.whenOrNull(
                data: (profile) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: LevelBadge(
                      level: profile.level,
                      size: 32,
                      showLabel: false,
                    ),
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: profileAsync.when(
        loading: () => const AppLoadingWidget(message: 'Cargando...'),
        error: (_, __) => const SizedBox.shrink(),
        data: (profile) => _HomeContent(
          profile: profile,
          homeState: homeState,
        ),
      ),
    );
  }
}

// ─── Content dispatcher ─────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.profile, required this.homeState});

  final OperatorProfile profile;
  final HomeState homeState;

  @override
  Widget build(BuildContext context) {
    return switch (homeState) {
      HomeStateActiveTrip(:final trip) => _ActiveTripView(
          profile: profile,
          trip: trip,
        ),
      HomeStateReturning(:final recentTrips, :final recentPoints) =>
        _WelcomeBackView(
          profile: profile,
          recentTrips: recentTrips,
          recentPoints: recentPoints,
        ),
      HomeStateDashboard(
        :final monthTrips,
        :final totalKm,
        :final totalPoints,
        :final streak,
      ) =>
        _DashboardView(
          profile: profile,
          monthTrips: monthTrips,
          totalKm: totalKm,
          totalPoints: totalPoints,
          streak: streak,
        ),
    };
  }
}

// ─── Case A: active trip ────────────────────────────────────────────────────

class _ActiveTripView extends StatelessWidget {
  const _ActiveTripView({required this.profile, required this.trip});

  final OperatorProfile profile;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = profile.fullName.split(' ').first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '¡Hola, $firstName!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tienes un viaje en curso.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondaryDark),
            ).animate().fadeIn(duration: 400.ms, delay: 60.ms),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ActiveTripCard(trip: trip),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 120.ms)
              .slideY(begin: 0.15, end: 0),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PointsBalanceCard(
              availablePoints: profile.availablePoints,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Case B: returning user ─────────────────────────────────────────────────

class _WelcomeBackView extends StatelessWidget {
  const _WelcomeBackView({
    required this.profile,
    required this.recentTrips,
    required this.recentPoints,
  });

  final OperatorProfile profile;
  final List<Trip> recentTrips;
  final int recentPoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = profile.fullName.split(' ').first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '¡Bienvenido de\nvuelta, $firstName!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
          ),
          if (recentPoints > 0) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PointsBadge(points: recentPoints),
            ).animate().fadeIn(duration: 400.ms, delay: 80.ms),
          ],
          const SizedBox(height: 16),
          ...recentTrips.map(
            (t) => TripCard(
              trip: t,
              onTap: () => context.push('/trips/${t.id}'),
            )
                .animate()
                .fadeIn(duration: 350.ms, delay: 120.ms)
                .slideY(begin: 0.1, end: 0),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PointsBalanceCard(
              availablePoints: profile.availablePoints,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 320.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Case C: dashboard ──────────────────────────────────────────────────────

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.profile,
    required this.monthTrips,
    required this.totalKm,
    required this.totalPoints,
    required this.streak,
  });

  final OperatorProfile profile;
  final List<Trip> monthTrips;
  final double totalKm;
  final int totalPoints;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = profile.fullName.split(' ').first;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '¡Hola, $firstName!',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Emp. ${profile.employeeNumber}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondaryDark),
            ).animate().fadeIn(duration: 400.ms, delay: 60.ms),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MonthStatsRow(
              tripCount: monthTrips.length,
              totalKm: totalKm,
              totalPoints: totalPoints,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.1, end: 0),
          if (streak > 0) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StreakCard(streak: streak),
            ).animate().fadeIn(duration: 400.ms, delay: 180.ms),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PointsBalanceCard(
              availablePoints: profile.availablePoints,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 240.ms),
          if (monthTrips.isEmpty) ...[
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _NoTripPlaceholder(),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ─────────────────────────────────────────────────────

class _MonthStatsRow extends StatelessWidget {
  const _MonthStatsRow({
    required this.tripCount,
    required this.totalKm,
    required this.totalPoints,
  });

  final int tripCount;
  final double totalKm;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.route_outlined,
            label: 'Viajes\neste mes',
            value: '$tripCount',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.local_shipping_outlined,
            label: 'KM\ntotales',
            value: '${totalKm.toStringAsFixed(0)} km',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.stars_rounded,
            label: 'Puntos\nganados',
            value: '+$totalPoints',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.amber.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.amber.withAlpha(80)),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak ${streak == 1 ? 'día' : 'días'} consecutivos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                    ),
                  ),
                  Text(
                    '¡Sigue así, sin parar!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsBalanceCard extends StatelessWidget {
  const _PointsBalanceCard({required this.availablePoints});

  final int availablePoints;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.push('/points'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A2800), Color(0xFF2A1800)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.amber.withAlpha(40)),
        ),
        child: Row(
          children: [
            const Icon(Icons.stars_rounded, color: AppColors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$availablePoints pts disponibles',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ver historial de puntos →',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.amber.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.stars_rounded, color: AppColors.amber, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '+$points puntos mientras estuviste fuera',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoTripPlaceholder extends StatelessWidget {
  const _NoTripPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.asphaltCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.asphaltBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.amber,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin viajes este mes',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu próxima ruta aparecerá aquí',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }
}
