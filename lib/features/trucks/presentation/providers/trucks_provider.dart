import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/trucks/data/repositories/trucks_repository_impl.dart';
import 'package:operadorapp/features/trucks/domain/entities/truck.dart';
import 'package:operadorapp/features/trucks/domain/repositories/trucks_repository.dart';

final trucksRepositoryProvider = Provider<TrucksRepository>((ref) {
  return TrucksRepositoryImpl(ref.watch(appDatabaseProvider).trucksDao);
});

final truckSummariesProvider = StreamProvider<List<TruckSummary>>((ref) {
  final operadorId = ref.watch(profileProvider).value?.id;
  if (operadorId == null) return const Stream.empty();
  return ref
      .watch(trucksRepositoryProvider)
      .watchByOperador(operadorId)
      .map((e) => e.getOrElse((_) => []));
});

// FutureProvider.family produce un tipo no obvio; explícito sería verboso.
// ignore: specify_nonobvious_property_types
final truckReportsProvider =
    FutureProvider.family<List<TruckReport>, String>(
  (ref, tractoId) async {
    final result =
        await ref.watch(trucksRepositoryProvider).getReportes(tractoId);
    return result.getOrElse((_) => []);
  },
);

// FutureProvider.family produce un tipo no obvio; explícito sería verboso.
// ignore: specify_nonobvious_property_types
final truckRendimientoProvider =
    FutureProvider.family<double?, (String, String)>(
  (ref, args) async {
    final (tractoId, operadorId) = args;
    final result = await ref
        .watch(trucksRepositoryProvider)
        .getRendimientoPromedio(tractoId, operadorId);
    return result.getOrElse((_) => null);
  },
);
