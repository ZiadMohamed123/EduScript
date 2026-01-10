import 'package:flutter/material.dart';

/// Central place for colors and theming.
class AppColors {
  static const primary = Color(0xFF1E88E5); // blue 600
  static const primaryDark = Color(0xFF1565C0); // blue 800
  static const accent = Color(0xFF64B5F6); // blue 300
  static const background = Color(0xFFF6F8FB);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);

  // Additional blue shades (expanding palette)
  static const blue50 = Color(0xFFE3F2FD); // blue 50
  static const blue100 = Color(0xFFBBDEFB); // blue 100
  static const blue200 = Color(0xFF90CAF9); // blue 200
  static const blue400 = Color(0xFF42A5F5); // blue 400
  static const blue500 = Color(0xFF2196F3); // blue 500
  static const blue700 = Color(0xFF1976D2); // blue 700
  static const blue900 = Color(0xFF0D47A1); // blue 900

  // Vibrant accent colors (complementary to blue palette)
  static const cyan = Color(0xFF00BCD4); // cyan 500
  static const cyanLight = Color(0xFF4DD0E1); // cyan 300
  static const cyanDark = Color(0xFF0097A7); // cyan 700
  static const teal = Color(0xFF009688); // teal 500
  static const tealLight = Color(0xFF4DB6AC); // teal 300
  static const indigo = Color(0xFF3F51B5); // indigo 500
  static const indigoLight = Color(0xFF7986CB); // indigo 300
  static const purple = Color(0xFF9C27B0); // purple 500
  static const purpleLight = Color(0xFFBA68C8); // purple 300
  static const amber = Color(0xFFFFC107); // amber 500
  static const orange = Color(0xFFFF9800); // orange 500
  static const orangeLight = Color(0xFFFFB74D); // orange 300

  // Dark palette
  static const backgroundDark = Color(0xFF0B1220);
  static const surfaceDark = Color(0xFF111827);
  static const textPrimaryDark = Color(0xFFE5E7EB);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  
  // Additional dark mode shades
  static const surfaceDarkVariant = Color(0xFF1F2937);
  static const primaryDarkVariant = Color(0xFF1976D2); // blue 700 for dark mode
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        surfaceTintColor: AppColors.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.surfaceDark,
      background: AppColors.backgroundDark,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        surfaceTintColor: AppColors.surfaceDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
