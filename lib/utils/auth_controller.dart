import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// Authentication Controller
/// Manages authentication state across the app
/// Similar to ThemeController, uses ValueNotifier for reactive updates
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
      final user = await _authService.getCurrentUser();
      _currentUser.value = user;
    }
  }

  /// Sign up a new user
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

    if (result.success) {
      _isLoggedIn.value = true;
      _currentUser.value = result.user;
    }

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
    }

    return result;
  }

  /// Log out the current user
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn.value = false;
    _currentUser.value = null;
  }
}

