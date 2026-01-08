import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';
import 'settings_controller.dart';
import 'theme_controller.dart';

/// Authentication Controller
/// Manages authentication state across the app
class AuthController {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  final ValueNotifier<bool> _isLoggedIn = ValueNotifier<bool>(false);
  final ValueNotifier<User?> _currentUser = ValueNotifier<User?>(null);

  ValueListenable<bool> get isLoggedIn => _isLoggedIn;
  ValueListenable<User?> get currentUser => _currentUser;

  final AuthService _authService = AuthService();

  /// Initialize auth state (call this in main.dart or splash screen)
  Future<void> initialize() async {
    final loggedIn = await _authService.isLoggedIn();
    _isLoggedIn.value = loggedIn;

    if (loggedIn) {
      // Fetch user data from API using JWT token
      final user = await _authService.getCurrentUser();
      _currentUser.value = user;
      
      // Load user settings and apply them
      await _loadUserSettings();
    } else {
      // Reset to defaults when not logged in
      _resetToDefaults();
    }
  }

  /// Load user settings and apply them
  Future<void> _loadUserSettings() async {
    try {
      final settingsController = SettingsController();
      await settingsController.initialize();
      
      // Apply dark mode from settings
      final isDarkMode = settingsController.darkModeEnabled.value;
      ThemeController.instance.updateThemeFromSettings(isDarkMode);
      
      // Initialize theme controller with settings controller
      ThemeController.instance.initialize(settingsController);
    } catch (e) {
      debugPrint('Failed to load user settings: $e');
    }
  }

  /// Reset to default settings (light mode)
  void _resetToDefaults() {
    SettingsController().resetToDefaults();
    ThemeController.instance.resetToLight();
  }

  /// Sign up a new user
  /// Note: After signup, user needs to login to get JWT token
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _authService.signUp(
      name: name,
      email: email,
      password: password,
    );

    // Don't automatically log in after signup
    // User needs to login to get JWT token
    // The signup endpoint doesn't return a token

    return result;
  }

  /// Log in an existing user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final result = await _authService.login(
      email: email,
      password: password,
    );

    if (result.success) {
      _isLoggedIn.value = true;
      _currentUser.value = result.user;
      
      // Load user settings and apply them
      await _loadUserSettings();
    }

    return result;
  }

  /// Refresh current user data from API (call after profile updates)
  Future<void> refreshUser() async {
    if (_isLoggedIn.value) {
      // Fetch fresh user data from API using JWT token
      final user = await _authService.getCurrentUser();
      _currentUser.value = user;
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn.value = false;
    _currentUser.value = null;
    
    // Clear document cache to prevent showing other users' documents
    // Import and clear cache from DocumentService
    final documentService = DocumentService();
    documentService.clearCache();
    
    // Reset to default settings (light mode)
    _resetToDefaults();
  }
}