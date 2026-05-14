import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';

// ─── HomeState ──────────────────────────────────────────────────────────────

sealed class HomeState {
  const HomeState();
}

final class HomeStateActiveTrip extends HomeState {
  const HomeStateActiveTrip({required this.trip});

  final Trip trip;
}

final class HomeStateReturning extends HomeState {
  const HomeStateReturning({
    required this.recentTrips,
    required this.recentPoints,
  });

  final List<Trip> recentTrips;
  final int recentPoints;
}

final class HomeStateDashboard extends HomeState {
  const HomeStateDashboard({
    required this.monthTrips,
    required this.totalKm,
    required this.totalPoints,
    required this.streak,
  });

  final List<Trip> monthTrips;
  final double totalKm;
  final int totalPoints;
  final int streak;
}

// ─── Provider ───────────────────────────────────────────────────────────────

const _kLastSeenKey = 'home_last_seen_ms';

// Called from HomeScreen.initState to persist the last visit timestamp.
void updateHomLastSeen(WidgetRef ref) {
  unawaited(
    ref.read(sharedPreferencesProvider).setInt(
          _kLastSeenKey,
          DateTime.now().millisecondsSinceEpoch,
        ),
  );
}

final homeStateProvider = Provider<HomeState>((ref) {
  final trips = ref.watch(tripsProvider).value ?? const [];

  // Case A: active trip
  final activeTrip =
      trips.firstWhereOrNull((t) => t.estado == TripStatus.enCurso);
  if (activeTrip != null) {
    return HomeStateActiveTrip(trip: activeTrip);
  }

  // Check returning user (last seen > 24 h)
  final prefs = ref.watch(sharedPreferencesProvider);
  final lastSeenMs = prefs.getInt(_kLastSeenKey);
  final isReturning = lastSeenMs != null &&
      (DateTime.now().millisecondsSinceEpoch - lastSeenMs) >
          const Duration(hours: 24).inMilliseconds;

  // Case B: returning user
  if (isReturning && trips.isNotEmpty) {
    final recentTrips = trips.take(3).toList();
    final recentPoints = recentTrips.fold(0, (s, t) => s + t.puntosObtenidos);
    return HomeStateReturning(
      recentTrips: recentTrips,
      recentPoints: recentPoints,
    );
  }

  // Case C: regular dashboard
  final now = DateTime.now();
  final monthTrips = trips.where((t) {
    final date = t.fechaInicio ?? t.createdAt;
    return date.year == now.year && date.month == now.month;
  }).toList();
  final totalKm =
      monthTrips.fold<double>(0, (s, t) => s + (t.kmRecorridos ?? 0));
  final totalPoints = monthTrips.fold(0, (s, t) => s + t.puntosObtenidos);

  return HomeStateDashboard(
    monthTrips: monthTrips,
    totalKm: totalKm,
    totalPoints: totalPoints,
    streak: _computeStreak(trips),
  );
});

// ─── Streak helper ──────────────────────────────────────────────────────────

int _computeStreak(List<Trip> trips) {
  final dates = trips
      .where((t) => t.estado == TripStatus.completado && t.fechaFin != null)
      .map((t) {
        final d = t.fechaFin!;
        return DateTime(d.year, d.month, d.day);
      })
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  if (dates.isEmpty) return 0;

  final today = DateTime(now.year, now.month, now.day);
  // Streak is still active only if there was a trip today or yesterday
  if (dates.first.isBefore(today.subtract(const Duration(days: 1)))) return 0;

  var streak = 0;
  var expected = dates.first;
  for (final date in dates) {
    if (date == expected) {
      streak++;
      expected = expected.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }
  return streak;
}

DateTime get now => DateTime.now();
