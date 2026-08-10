import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/auth/presentation/providers/auth_provider.dart';
import 'package:operadorapp/features/profile/presentation/providers/profile_provider.dart';
import 'package:operadorapp/features/ranking/domain/entities/ranking_entry.dart';
import 'package:operadorapp/features/ranking/presentation/providers/ranking_provider.dart';

/// Vuelve a jalar del servidor lo que pudo cambiar con la app fuera de foco.
///
/// Cada repositorio dispara su `unawaited(sync...)` al ABRIR el stream de
/// Drift, una sola vez. Al volver del segundo plano esos streams siguen vivos,
/// así que nadie vuelve a preguntarle a Supabase: la app se queda con lo que
/// tenía cacheado hasta que se la mata y se la abre de nuevo. Por eso el
/// regreso desde segundo plano tiene que pedir la sincronización a mano.
///
/// Ningún `syncXxx` lanza —todos atrapan y registran—, así que el `Future.wait`
/// no puede romperse por uno que falle.
Future<void> refreshFromServer(WidgetRef ref) async {
  // Se lee todo antes del primer `await`: si el widget que llamó se desmonta
  // a media sincronización, un `ref.read` posterior reventaría.
  final sync = ref.read(syncServiceProvider);
  // Gotcha 16: `auth_user_id` solo sirve para la tabla `operadores`; el resto
  // de las tablas referencian el PK propio del operador.
  final authUserId = ref.read(authStateProvider).value?.operatorId;
  final operadorId = ref.read(profileProvider).value?.id;
  final periodo = ref.read(rankingPeriodoProvider).value;

  await Future.wait([
    if (authUserId != null && authUserId.isNotEmpty)
      sync.syncProfile(authUserId),
    if (operadorId != null) ...[
      sync.syncTrips(operadorId),
      sync.syncMovimientos(operadorId),
    ],
    sync.syncRanking(periodo),
  ]);
}
