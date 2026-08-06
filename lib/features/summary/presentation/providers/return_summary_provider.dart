import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/ranking/presentation/providers/ranking_provider.dart';
import 'package:operadorapp/features/summary/data/datasources/return_snapshot_store.dart';
import 'package:operadorapp/features/summary/domain/entities/return_summary.dart';
import 'package:operadorapp/features/trips/domain/entities/trip.dart';
import 'package:operadorapp/features/trips/presentation/providers/trips_provider.dart';

final returnSnapshotStoreProvider = Provider<ReturnSnapshotStore>(
  (ref) => ReturnSnapshotStore(ref.watch(sharedPreferencesProvider)),
);

/// Se pone en true cuando el resumen ya se mostró en esta sesión de app.
///
/// El store conserva el snapshot anterior en memoria durante toda la sesión,
/// así que sin esta bandera el popup volvería a dispararse cada vez que
/// Riverpod recalculara el provider.
final returnSummaryShownProvider = StateProvider<bool>((_) => false);

/// Resumen de lo ocurrido con la app cerrada, o null si no hay nada que contar.
final returnSummaryProvider = Provider<ReturnSummary?>((ref) {
  final previous = ref.watch(returnSnapshotStoreProvider).previous;
  // Primer arranque: no hay contra qué comparar, solo se guardará el snapshot.
  if (previous == null) return null;

  final profile = ref.watch(profileProvider).value;
  if (profile == null) return null;

  final trips = ref.watch(tripsProvider).value ?? const <Trip>[];

  final completed = trips
      .where(
        (t) =>
            t.estado == TripStatus.completado &&
            (t.fechaFin ?? t.updatedAt).isAfter(previous.savedAt),
      )
      .toList()
    ..sort((a, b) {
      final fa = a.fechaFin ?? a.updatedAt;
      final fb = b.fechaFin ?? b.updatedAt;
      return fb.compareTo(fa);
    });

  final summary = ReturnSummary(
    completedTrips: completed,
    pointsBefore: previous.points,
    pointsAfter: profile.totalPoints,
    levelBefore: previous.level,
    levelAfter: profile.level,
    since: previous.savedAt,
    rankBefore: previous.rankGlobal,
    // Puede ser null en un arranque en frío sin ranking cacheado; en ese caso
    // el resumen simplemente no muestra el renglón de lugares.
    rankAfter: ref.watch(myRankingEntryProvider)?.posicion,
  );

  return summary.hasContent ? summary : null;
});

/// Guarda el estado actual como nuevo punto de comparación.
///
/// Se llama al cerrar el resumen y cuando la app pasa a segundo plano: son los
/// dos momentos en los que "esto ya lo vio el operador" es cierto.
Future<void> saveReturnSnapshot(WidgetRef ref) async {
  final profile = ref.read(profileProvider).value;
  if (profile == null) return;

  await ref.read(returnSnapshotStoreProvider).save(
        points: profile.totalPoints,
        level: profile.level,
        rankGlobal: ref.read(myRankingEntryProvider)?.posicion,
      );
}
