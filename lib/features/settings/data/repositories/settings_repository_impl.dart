import 'package:operadorapp/core/constants/app_constants.dart';
import 'package:operadorapp/features/settings/domain/entities/app_settings.dart';
import 'package:operadorapp/features/settings/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<AppSettings> getSettings() async {
    final themeStr = _prefs.getString(AppConstants.themeKey);
    return AppSettings(
      themeMode: AppThemeModeX.fromString(themeStr),
      pushNotificationsEnabled:
          _prefs.getBool(AppConstants.pushNotifKey) ?? true,
      inAppNotificationsEnabled:
          _prefs.getBool(AppConstants.inAppNotifKey) ?? true,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(
      AppConstants.themeKey,
      settings.themeMode.persistedValue,
    );
    await _prefs.setBool(
      AppConstants.pushNotifKey,
      settings.pushNotificationsEnabled,
    );
    await _prefs.setBool(
      AppConstants.inAppNotifKey,
      settings.inAppNotificationsEnabled,
    );
  }
}
