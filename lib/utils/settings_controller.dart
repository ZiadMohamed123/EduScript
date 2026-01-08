import 'package:flutter/foundation.dart';
import '../services/user_service.dart';

/// Settings Controller
/// Manages user settings (dark mode, language, etc.) across the app
class SettingsController {
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  final ValueNotifier<bool> _darkModeEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<String> _language = ValueNotifier<String>('English');

  ValueListenable<bool> get darkModeEnabled => _darkModeEnabled;
  ValueListenable<String> get language => _language;

  final UserService _userService = UserService();

  /// Initialize settings from API
  Future<void> initialize() async {
    try {
      final profileData = await _userService.getUserProfile();
      final settings = profileData['settings'] as Map<String, dynamic>?;
      
      if (settings != null) {
        final darkModeValue = settings['is_dark_mode_open'] as bool? ?? false;
        _darkModeEnabled.value = darkModeValue;
        _language.value = settings['language'] as String? ?? 'English';
        debugPrint('Settings loaded: darkMode=$darkModeValue');
      } else {
        debugPrint('No settings found in profile data');
        // Use defaults
        _darkModeEnabled.value = false;
      }
    } catch (e) {
      // If settings can't be loaded, use defaults
      debugPrint('Failed to load settings: $e');
      _darkModeEnabled.value = false;
    }
  }

  /// Reset to default settings (used on logout)
  void resetToDefaults() {
    _darkModeEnabled.value = false;
    _language.value = 'English';
  }

  /// Toggle dark mode setting
  Future<void> toggleDarkMode() async {
    try {
      // Optimistically update UI first for better UX
      final currentValue = _darkModeEnabled.value;
      debugPrint('Toggling dark mode from $currentValue to ${!currentValue}');
      _darkModeEnabled.value = !currentValue;
      
      // Then sync with backend
      final result = await _userService.toggleDarkMode();
      final isEnabled = result['is_dark_mode_open'] as bool?;
      debugPrint('Backend response: is_dark_mode_open=$isEnabled');
      
      // Update with actual value from backend
      if (isEnabled != null) {
        _darkModeEnabled.value = isEnabled;
      }
    } catch (e) {
      debugPrint('Failed to toggle dark mode: $e');
      // Revert on error
      _darkModeEnabled.value = !_darkModeEnabled.value;
      rethrow;
    }
  }

  /// Update language setting
  Future<void> updateLanguage(String language) async {
    try {
      await _userService.updateLanguage(language);
      _language.value = language;
    } catch (e) {
      debugPrint('Failed to update language: $e');
      rethrow;
    }
  }

  /// Refresh settings from API
  Future<void> refresh() async {
    await initialize();
  }
}

