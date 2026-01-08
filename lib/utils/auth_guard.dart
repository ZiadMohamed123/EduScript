import 'package:flutter/material.dart';
import '../utils/auth_controller.dart';
import '../services/auth_service.dart';

/// Authentication Guard Widget
/// Wraps protected routes and redirects to login if user is not authenticated
class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Check authentication status from the service
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (mounted) {
      setState(() {
        _isAuthenticated = isLoggedIn;
        _isChecking = false;
      });

      // If not authenticated, redirect to login
      if (!isLoggedIn) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking authentication
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If not authenticated, show loading (redirect will happen)
    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // User is authenticated, show the protected content
    // Also listen to auth state changes
    return ValueListenableBuilder<bool>(
      valueListenable: AuthController().isLoggedIn,
      builder: (context, isLoggedIn, _) {
        if (!isLoggedIn) {
          // Auth state changed to logged out, redirect
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return widget.child;
      },
    );
  }
}
