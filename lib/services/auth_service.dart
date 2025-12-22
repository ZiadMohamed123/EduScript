import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// User model for authentication
class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Backend returns "user_id" but we may also support "id"
    final id = (json['user_id'] ?? json['id']) as String;
    return User(
      id: id,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

/// Authentication Service
/// Handles login, signup, logout, and session management
/// Uses backend API + SharedPreferences for local storage
class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyAuthToken = 'auth_token';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final userId = prefs.getString(_keyUserId);
    final userName = prefs.getString(_keyUserName);
    final userEmail = prefs.getString(_keyUserEmail);

    if (userId == null || userName == null || userEmail == null) {
      return null;
    }

    return User(id: userId, name: userName, email: userEmail);
  }

  /// Get stored auth token (JWT) if available
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  /// Sign up a new user using backend API
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // Validate inputs
    if (name.trim().isEmpty) {
      return AuthResult(success: false, message: 'Please enter your name');
    }

    if (!_isValidEmail(email)) {
      return AuthResult(
        success: false,
        message: 'Please enter a valid email address',
      );
    }

    if (password.length < 8) {
      return AuthResult(
        success: false,
        message: 'Password must be at least 8 characters',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    final uri = Uri.parse('${ApiConfig.backendBaseUrl}/auth/signup');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userJson = data['user'] as Map<String, dynamic>;
        final user = User.fromJson(userJson);

        // Note: signup endpoint does not return token in docs,
        // so we just mark user as created and logged in locally.
        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, user.id);
        await prefs.setString(_keyUserName, user.name);
        await prefs.setString(_keyUserEmail, user.email);

        return AuthResult(
          success: true,
          message:
              data['message'] as String? ?? 'Account created successfully!',
          user: user,
        );
      } else if (response.statusCode == 400) {
        return AuthResult(
          success: false,
          message: 'Missing required fields. Please check your input.',
        );
      } else if (response.statusCode == 409) {
        return AuthResult(
          success: false,
          message: 'An account with this email already exists',
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Failed to create account. Please try again.',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Could not connect to server. Please try again.',
      );
    }
  }

  /// Log in an existing user using backend API
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (!_isValidEmail(email)) {
      return AuthResult(
        success: false,
        message: 'Please enter a valid email address',
      );
    }

    if (password.isEmpty) {
      return AuthResult(success: false, message: 'Please enter your password');
    }

    final prefs = await SharedPreferences.getInstance();

    final uri = Uri.parse('${ApiConfig.backendBaseUrl}/auth/login');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>;
        final user = User.fromJson(userJson);

        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, user.id);
        await prefs.setString(_keyUserName, user.name);
        await prefs.setString(_keyUserEmail, user.email);
        if (token != null) {
          await prefs.setString(_keyAuthToken, token);
        }

        return AuthResult(
          success: true,
          message: data['message'] as String? ?? 'Login successful!',
          user: user,
        );
      } else if (response.statusCode == 400) {
        return AuthResult(
          success: false,
          message: 'Missing email or password.',
        );
      } else if (response.statusCode == 401) {
        return AuthResult(success: false, message: 'Invalid email or password');
      } else {
        return AuthResult(
          success: false,
          message: 'Failed to login. Please try again.',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Could not connect to server. Please try again.',
      );
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyAuthToken);
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Result of authentication operations
class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({required this.success, required this.message, this.user});
}
