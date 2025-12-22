import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'settings_controller.dart';

class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  SettingsController? _settingsController;

  bool get isDark => themeMode.value == ThemeMode.dark;

  /// Initialize theme controller with settings controller
  void initialize(SettingsController settingsController) {
    _settingsController = settingsController;
    
    // Listen to dark mode changes from settings
    settingsController.darkModeEnabled.addListener(_onDarkModeChanged);
    
    // Set initial theme from settings
    updateThemeFromSettings(settingsController.darkModeEnabled.value);
  }

  void _onDarkModeChanged() {
    if (_settingsController != null) {
      updateThemeFromSettings(_settingsController!.darkModeEnabled.value);
    }
  }

  /// Update theme from settings (called by AuthController)
  void updateThemeFromSettings(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void setTheme(ThemeMode mode) {
    themeMode.value = mode;
  }

  /// Toggle dark mode and save to backend
  Future<void> toggleDark(bool enabled) async {
    if (_settingsController != null) {
      // Update theme immediately
      themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
      
      // Always save to backend when toggled
      try {
        await _settingsController!.toggleDarkMode();
      } catch (e) {
        debugPrint('Failed to save dark mode to backend: $e');
        // Revert on error
        themeMode.value = enabled ? ThemeMode.light : ThemeMode.dark;
        rethrow;
      }
    } else {
      // Fallback if settings controller not initialized
      themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
      debugPrint('Warning: SettingsController not initialized, dark mode not saved to backend');
    }
  }

  /// Reset to light mode (used on logout)
  void resetToLight() {
    themeMode.value = ThemeMode.light;
  }
}
