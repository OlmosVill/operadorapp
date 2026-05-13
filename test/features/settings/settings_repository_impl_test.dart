import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:operadorapp/core/constants/app_constants.dart';
import 'package:operadorapp/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:operadorapp/features/settings/domain/entities/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SettingsRepositoryImpl sut;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    sut = SettingsRepositoryImpl(mockPrefs);
  });

  group('SettingsRepositoryImpl.getSettings —', () {
    test(
      'devuelve valores por defecto cuando SharedPreferences está vacío',
      () async {
        when(() => mockPrefs.getString(AppConstants.themeKey))
            .thenReturn(null);
        when(() => mockPrefs.getBool(AppConstants.pushNotifKey))
            .thenReturn(null);
        when(() => mockPrefs.getBool(AppConstants.inAppNotifKey))
            .thenReturn(null);

        final settings = await sut.getSettings();

        expect(settings.themeMode, AppThemeMode.system);
        expect(settings.pushNotificationsEnabled, isTrue);
        expect(settings.inAppNotificationsEnabled, isTrue);
      },
    );

    test('deserializa el themeMode guardado correctamente', () async {
      when(() => mockPrefs.getString(AppConstants.themeKey))
          .thenReturn('dark');
      when(() => mockPrefs.getBool(AppConstants.pushNotifKey))
          .thenReturn(true);
      when(() => mockPrefs.getBool(AppConstants.inAppNotifKey))
          .thenReturn(true);

      final settings = await sut.getSettings();

      expect(settings.themeMode, AppThemeMode.dark);
    });

    test('lee los valores de notificaciones guardados', () async {
      when(() => mockPrefs.getString(AppConstants.themeKey)).thenReturn(null);
      when(() => mockPrefs.getBool(AppConstants.pushNotifKey))
          .thenReturn(false);
      when(() => mockPrefs.getBool(AppConstants.inAppNotifKey))
          .thenReturn(false);

      final settings = await sut.getSettings();

      expect(settings.pushNotificationsEnabled, isFalse);
      expect(settings.inAppNotificationsEnabled, isFalse);
    });
  });

  group('SettingsRepositoryImpl.saveSettings —', () {
    test('persiste todos los campos de AppSettings', () async {
      when(
        () => mockPrefs.setString(AppConstants.themeKey, 'light'),
      ).thenAnswer((_) async => true);
      when(
        () => mockPrefs.setBool(AppConstants.pushNotifKey, false),
      ).thenAnswer((_) async => true);
      when(
        () => mockPrefs.setBool(AppConstants.inAppNotifKey, true),
      ).thenAnswer((_) async => true);

      const settings = AppSettings(
        themeMode: AppThemeMode.light,
        pushNotificationsEnabled: false,
      );

      await sut.saveSettings(settings);

      verify(
        () => mockPrefs.setString(AppConstants.themeKey, 'light'),
      ).called(1);
      verify(
        () => mockPrefs.setBool(AppConstants.pushNotifKey, false),
      ).called(1);
      verify(
        () => mockPrefs.setBool(AppConstants.inAppNotifKey, true),
      ).called(1);
    });
  });
}
