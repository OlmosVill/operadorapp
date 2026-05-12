import 'package:flutter/material.dart';

enum AppThemeMode { light, dark, system }

extension AppThemeModeX on AppThemeMode {
  ThemeMode toFlutterThemeMode() => switch (this) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  String get persistedValue => switch (this) {
        AppThemeMode.light => 'light',
        AppThemeMode.dark => 'dark',
        AppThemeMode.system => 'system',
      };

  String get displayName => switch (this) {
        AppThemeMode.light => 'Claro',
        AppThemeMode.dark => 'Oscuro',
        AppThemeMode.system => 'Sistema',
      };

  static AppThemeMode fromString(String? value) => switch (value) {
        'light' => AppThemeMode.light,
        'dark' => AppThemeMode.dark,
        _ => AppThemeMode.system,
      };
}

class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.pushNotificationsEnabled = true,
    this.inAppNotificationsEnabled = true,
  });

  final AppThemeMode themeMode;
  final bool pushNotificationsEnabled;
  final bool inAppNotificationsEnabled;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? pushNotificationsEnabled,
    bool? inAppNotificationsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      inAppNotificationsEnabled:
          inAppNotificationsEnabled ?? this.inAppNotificationsEnabled,
    );
  }
}
