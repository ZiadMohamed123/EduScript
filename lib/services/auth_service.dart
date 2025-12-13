import 'package:shared_preferences/shared_preferences.dart';

/// User model for authentication
class User {
  final String id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
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

    return User(
      id: userId,
      name: userName,
      email: userEmail,
    );
  }

  /// Sign up a new user
  /// In a real app, this would call a backend API
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

    final prefs = await SharedPreferences.getInstance();

    // Check if user already exists
    final usersJson = prefs.getString(_keyUsers);
    final users = usersJson != null
        ? (usersJson.split('|').where((e) => e.isNotEmpty).toList())
        : <String>[];

    // Check if email is already registered
    for (final userData in users) {
      final parts = userData.split(':');
      if (parts.length >= 2 && parts[1] == email) {
        return AuthResult(
          success: false,
          message: 'An account with this email already exists',
        );
      }
    }

    // Create new user
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    final userData = '$userId:$email:$password:$name';
    users.add(userData);

    // Save users list
    await prefs.setString(_keyUsers, users.join('|'));

    // Auto-login after signup
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);

    return AuthResult(
      success: true,
      message: 'Account created successfully!',
      user: User(id: userId, name: name, email: email),
    );
  }

  /// Log in an existing user
  /// In a real app, this would call a backend API
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
      return AuthResult(
        success: false,
        message: 'Please enter your password',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    // Get registered users
    final usersJson = prefs.getString(_keyUsers);
    final users = usersJson != null
        ? (usersJson.split('|').where((e) => e.isNotEmpty).toList())
        : <String>[];

    // Find user with matching email and password
    for (final userData in users) {
      final parts = userData.split(':');
      if (parts.length >= 4 &&
          parts[1] == email &&
          parts[2] == password) {
        // Login successful
        final userId = parts[0];
        final userName = parts[3];

        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setString(_keyUserId, userId);
        await prefs.setString(_keyUserName, userName);
        await prefs.setString(_keyUserEmail, email);

        return AuthResult(
          success: true,
          message: 'Login successful!',
          user: User(id: userId, name: userName, email: email),
        );
      }
    }

    return AuthResult(
      success: false,
      message: 'Invalid email or password',
    );
  }

  /// Log out the current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
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

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

