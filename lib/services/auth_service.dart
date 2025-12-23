import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/http_client.dart';
import 'user_service.dart';

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
/// Uses SharedPreferences for local storage (can be replaced with backend API)
class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUsers = 'users'; // Store registered users
  static const String _keyAuthToken = 'auth_token';
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final UserService _userService = UserService();

  /// Check if user is currently logged in (has valid JWT token)
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return false;

    // Verify token is still valid by checking if we can fetch user data
    final token = await getAuthToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    // Optionally verify token is valid by making a lightweight API call
    // For now, just check if token exists
    return true;
  }

  /// Get current user from API using JWT token
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return null;

    final token = await getAuthToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      // Fetch user data from API using JWT token
      final profileData = await _userService.getUserProfile();
      final userData = profileData['user'] as Map<String, dynamic>?;

      if (userData != null) {
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      // If API call fails (e.g., token expired), clear login state
      await logout();
      return null;
    }
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
      return AuthResult(
        success: false,
        message: 'Please enter your name',
      );
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

    try {
      final response = await HttpClient.post(
        '/auth/signup',
        body: {'email': email, 'password': password, 'name': name},
        includeAuth: false, // Signup endpoint doesn't need auth
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userJson = data['user'] as Map<String, dynamic>;
        final user = User.fromJson(userJson);

        // Note: signup endpoint does not return token
        // User needs to login after signup to get JWT token
        // Don't mark as logged in - user must login separately

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

    try {
      final response = await HttpClient.post(
        '/auth/login',
        body: {'email': email, 'password': password},
        includeAuth: false, // Login endpoint doesn't need auth
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>;
        final user = User.fromJson(userJson);

        // Only store JWT token, not user details
        // User data will be fetched from API when needed
        await prefs.setBool(_keyIsLoggedIn, true);
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
