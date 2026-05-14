import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:operadorapp/features/settings/domain/entities/app_settings.dart';
import 'package:operadorapp/features/settings/domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.read(sharedPreferencesProvider)),
);

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repository) : super(const AppSettings()) {
    unawaited(_load());
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    final settings = await _repository.getSettings();
    state = settings;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repository.saveSettings(state);
  }

  Future<void> setPushNotificationsEnabled({required bool enabled}) async {
    state = state.copyWith(pushNotificationsEnabled: enabled);
    await _repository.saveSettings(state);
  }

  Future<void> setInAppNotificationsEnabled({required bool enabled}) async {
    state = state.copyWith(inAppNotificationsEnabled: enabled);
    await _repository.saveSettings(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.read(settingsRepositoryProvider)),
);
