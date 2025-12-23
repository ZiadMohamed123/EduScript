import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthController().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$action coming soon!')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Form(
                key: _formKey,
                child: isLandscape
                    ? Row(
                        children: [
                          _buildWelcome(scheme),
                          const SizedBox(width: 40),
                          Expanded(child: _buildForm(scheme)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildWelcome(scheme),
                          const SizedBox(height: 32),
                          _buildForm(scheme),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome(ColorScheme scheme) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome back',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Login to continue scanning and studying.',
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: _inputDecoration('Email', Icons.email, scheme),
          validator: (value) =>
              value != null && value.contains('@')
                  ? null
                  : 'Enter a valid email',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscure,
          enabled: !_isLoading,
          decoration: _inputDecoration(
            'Password',
            Icons.lock,
            scheme,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (value) =>
              value != null && value.isNotEmpty
                  ? null
                  : 'Enter your password',
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Login'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed:
              _isLoading ? null : () => Navigator.pushNamed(context, '/signup'),
          child: const Text('Create an account'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: scheme.outlineVariant)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('or continue with'),
            ),
            Expanded(child: Divider(color: scheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _SocialButton(
              label: 'Google',
              icon: Icons.g_mobiledata,
              onTap: () => _showComingSoon('Google sign-in'),
            ),
            _SocialButton(
              label: 'Apple',
              icon: Icons.apple,
              onTap: () => _showComingSoon('Apple sign-in'),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    ColorScheme scheme, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.surfaceVariant.withOpacity(0.4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
