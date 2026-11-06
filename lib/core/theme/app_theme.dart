import 'package:flutter/material.dart';

/// Palette: confident blue -> soft light purple, on a calm off-white canvas.
abstract final class AppColors {
  static const Color deepBlue = Color(0xFF1D4ED8);
  static const Color blue = Color(0xFF2563EB);
  static const Color indigo = Color(0xFF5B6CF0);
  static const Color purple = Color(0xFF7C6CF0);
  static const Color lightPurple = Color(0xFFC4B5FD);
  static const Color mist = Color(0xFFF5F6FF); // app background
  static const Color border = Color(0xFFE4E7F7);
  static const Color ink = Color(0xFF1B1F3B); // primary text
  static const Color muted = Color(0xFF565B80); // secondary text (AA on white)
  static const Color success = Color(0xFF15803D);
  static const Color error = Color(0xFFDC2626);
}

abstract final class AppGradients {
  /// Full-screen hero (login / lock): blue at the top, light purple glow below.
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.deepBlue, AppColors.indigo, AppColors.lightPurple],
    stops: [0.0, 0.55, 1.0],
  );

  /// Page headers: keeps white text on the darker blue side for contrast.
  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.deepBlue, AppColors.indigo],
  );

  /// Buttons and small accents.
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.blue, AppColors.purple],
  );
}

/// 8-point spacing scale. Every gap in the app comes from here.
abstract final class Space {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class Radii {
  static const double field = 14;
  static const double button = 16;
  static const double card = 20;
  static const double hero = 32;
}

/// Minimum comfortable touch target (Material + Apple HIG guidance).
const double kTouchTarget = 48;
const double kButtonHeight = 56;

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    primary: AppColors.blue,
    secondary: AppColors.purple,
    surface: Colors.white,
    error: AppColors.error,
  );

  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.field),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.mist,
    // Type scale: 28 / 22 / 16 / 14 - few sizes, clear hierarchy.
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: AppColors.ink,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.mist,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Space.m, vertical: 18),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.blue, 2),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 2),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.lightPurple.withValues(alpha: 0.45),
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(kButtonHeight),
        foregroundColor: AppColors.blue,
        side: const BorderSide(color: AppColors.blue, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(kTouchTarget, kTouchTarget),
        foregroundColor: AppColors.blue,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.field),
      ),
    ),
  );
}
