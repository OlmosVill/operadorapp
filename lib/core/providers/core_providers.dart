import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client — singleton global inicializado en main.dart
final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

// SharedPreferences — se inyecta desde main.dart vía override
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Debe sobreescribirse en ProviderScope'),
);

// Logger global
final loggerProvider = Provider<Logger>(
  (_) => Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
    ),
  ),
);
