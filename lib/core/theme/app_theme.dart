import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:operadorapp/core/theme/app_colors.dart';

abstract final class AppTheme {
  // Bold type scale — much stronger visual hierarchy than M3 defaults.
  // Headlines and titles use w700/w800 for industrial authority.
  static const _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
    ),
    displayMedium: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    ),
    displaySmall: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  // Shared radii — tighter than M3 defaults for an industrial feel.
  static const double _cardRadius = 10;
  static const double _buttonRadius = 8;
  static const double _inputRadius = 10;

  // ─── Dark theme ──────────────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        textTheme: _textTheme.apply(
          bodyColor: AppColors.textOnDark,
          displayColor: AppColors.textOnDark,
        ),
        colorScheme: const ColorScheme.dark(
          primary: AppColors.amber,
          primaryContainer: Color(0xFF4A2800),
          onPrimaryContainer: AppColors.amberLight,
          secondary: AppColors.silver,
          secondaryContainer: AppColors.asphaltCard,
          onSecondaryContainer: AppColors.textOnDark,
          surface: AppColors.asphaltSurface,
          onSurface: AppColors.textOnDark,
          surfaceContainerHighest: AppColors.asphaltCard,
          error: AppColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.asphalt,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.asphalt,
          foregroundColor: AppColors.textOnDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          shape: Border(
            bottom: BorderSide(color: AppColors.asphaltBorder),
          ),
          titleTextStyle: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.asphaltSurface,
          indicatorColor: AppColors.amber.withAlpha(28),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.amber, size: 24);
            }
            return const IconThemeData(
              color: AppColors.textSecondaryDark,
              size: 22,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.amber,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              );
            }
            return const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        cardTheme: CardThemeData(
          color: AppColors.asphaltCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: BorderSide(color: AppColors.asphaltBorder.withAlpha(200)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.amber.withAlpha(22),
          secondarySelectedColor: AppColors.amber.withAlpha(22),
          disabledColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.asphaltBorder),
          ),
          side: const BorderSide(color: AppColors.asphaltBorder),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryDark,
          ),
          secondaryLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.amber,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.asphaltCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: const BorderSide(color: AppColors.asphaltBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: const BorderSide(color: AppColors.amber, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
          prefixIconColor: AppColors.textSecondaryDark,
          suffixIconColor: AppColors.textSecondaryDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppColors.asphaltBorder,
            disabledForegroundColor: AppColors.textSecondaryDark,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            elevation: 0,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.amber,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.amber,
            side: const BorderSide(color: AppColors.amber),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.asphaltBorder,
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.amber,
          textColor: AppColors.textOnDark,
          titleTextStyle: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.amber;
            return AppColors.textSecondaryDark;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.amber.withAlpha(80);
            }
            return AppColors.asphaltBorder;
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.amber,
          linearTrackColor: AppColors.asphaltBorder,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.asphaltCard,
          contentTextStyle: const TextStyle(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: const BorderSide(color: AppColors.asphaltBorder),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.asphaltSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
      );

  // ─── Light theme ─────────────────────────────────────────────────────────

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        textTheme: _textTheme.apply(
          bodyColor: AppColors.textOnLight,
          displayColor: AppColors.textOnLight,
        ),
        colorScheme: const ColorScheme.light(
          primary: AppColors.amberDark,
          primaryContainer: Color(0xFFFFE0B2),
          onPrimaryContainer: Color(0xFF4A2800),
          secondary: Color(0xFF5A5855),
          secondaryContainer: Color(0xFFE2E1DC),
          onSecondaryContainer: AppColors.textOnLight,
          surface: Color(0xFFF5F4EF),
          onSurface: AppColors.textOnLight,
          surfaceContainerHighest: AppColors.concrete,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: const Color(0xFFEFEEE9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F4EF),
          foregroundColor: AppColors.textOnLight,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          shape: Border(
            bottom: BorderSide(color: Color(0xFFDEDDD8)),
          ),
          titleTextStyle: TextStyle(
            color: AppColors.textOnLight,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFFF5F4EF),
          indicatorColor: AppColors.amberDark.withAlpha(20),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.amberDark, size: 24);
            }
            return const IconThemeData(
              color: AppColors.textSecondaryLight,
              size: 22,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.amberDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              );
            }
            return const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: const BorderSide(color: Color(0xFFDEDDD8)),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.amberDark.withAlpha(14),
          secondarySelectedColor: AppColors.amberDark.withAlpha(14),
          disabledColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFDEDDD8)),
          ),
          side: const BorderSide(color: Color(0xFFDEDDD8)),
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryLight,
          ),
          secondaryLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.amberDark,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F4EF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: const BorderSide(color: Color(0xFFDEDDD8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: const BorderSide(color: AppColors.amberDark, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
          prefixIconColor: AppColors.textSecondaryLight,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amberDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            elevation: 0,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.amberDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.amberDark,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFDEDDD8),
          thickness: 1,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: AppColors.amberDark,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.amberDark;
            }
            return Colors.grey;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.amberDark.withAlpha(80);
            }
            return Colors.grey.shade300;
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.amberDark,
          linearTrackColor: Color(0xFFE0DFD9),
        ),
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFFF5F4EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
      );
}
