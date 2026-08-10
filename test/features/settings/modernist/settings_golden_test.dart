import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operadorapp/core/constants/app_constants.dart';
import 'package:operadorapp/core/providers/core_providers.dart';
import 'package:operadorapp/features/settings/presentation/screens/modernist/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../trips/modernist/modernist_golden_harness.dart';

/// Ajustes es la única vista sin export: se compuso con las piezas del sistema.
/// El golden sirve para comprobar que no se sale del lenguaje.
///
/// ```sh
/// flutter test --update-goldens test/features/settings/modernist
/// ```
void main() {
  for (final (name, brightness) in modernistThemes) {
    testWidgets('Configuración se ve como el resto del sistema $name',
        (tester) async {
      // El tema persistido decide qué opción sale marcada; se siembra en
      // prefs porque el notifier lo carga de ahí al construirse.
      SharedPreferences.setMockInitialValues({
        AppConstants.themeKey:
            brightness == Brightness.dark ? 'dark' : 'light',
      });

      await setUpModernistGolden(tester);
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const ModernistSettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(ModernistSettingsScreen),
        matchesGoldenFile('goldens/settings_$name.png'),
      );
    });
  }
}
