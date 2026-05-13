import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:operadorapp/core/database/app_database.dart';
import 'package:operadorapp/core/services/connectivity_service.dart';
import 'package:operadorapp/core/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Infraestructura ──────────────────────────────────────────────────────────

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// Inyectado desde main.dart vía override
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Debe sobreescribirse en ProviderScope'),
);

// Inyectado desde main.dart vía override
final appDatabaseProvider = Provider<AppDatabase>(
  (_) => throw UnimplementedError('Debe sobreescribirse en ProviderScope'),
);

final loggerProvider = Provider<Logger>(
  (_) => Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
    ),
  ),
);

// ─── Conectividad ─────────────────────────────────────────────────────────────

final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => ConnectivityService(Connectivity()),
);

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onlineStream;
});

// ─── Sincronización ───────────────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    db: ref.read(appDatabaseProvider),
    supabase: ref.read(supabaseClientProvider),
    logger: ref.read(loggerProvider),
  ),
);
