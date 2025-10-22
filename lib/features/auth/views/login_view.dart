// lib/features/auth/views/login_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import 'signup_view.dart';
import '../../../core/utils/validators.dart';
import '../../../core/errors/auth_errors.dart';
import '../models/form_cache.dart';
import '../../memory/views/memory_create_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignInInProgress = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() => _emailError = Validators.emailValidator(value));
  }

  void _validatePassword(String value) {
    setState(() => _passwordError = Validators.passwordValidator(value));
  }

  bool get _isFormValid =>
      _emailError == null &&
      _passwordError == null &&
      _emailController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty;

  Future<void> _signIn() async {
    if (!_isFormValid || _isLoading || _isSignInInProgress) return;

    final email = _emailController.text;
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _isSignInInProgress = true;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithPassword(email: email, password: password);
    } on AppAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (FormErrorCache.isRepeatedError(email, password, e.message)) {
        _showErrorSnackBar(
          'Por favor, corrige los datos antes de intentar nuevamente',
        );
      } else {
        FormErrorCache.cacheFailedAttempt(email, password, e.message);
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final errorMessage = 'Error: ${e.toString()}';
      if (FormErrorCache.isRepeatedError(email, password, errorMessage)) {
        _showErrorSnackBar(
          'Error persistente. Por favor, verifica tu conexión o intenta más tarde',
        );
      } else {
        FormErrorCache.cacheFailedAttempt(email, password, errorMessage);
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSignInInProgress = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                errorText: _emailError,
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: _validateEmail,
              onSubmitted: (_) => _signIn(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                errorText: _passwordError,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
              obscureText: _obscurePassword,
              onChanged: _validatePassword,
              onSubmitted: (_) => _signIn(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid && !_isLoading ? _signIn : null,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Iniciar Sesión'),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿No tienes cuenta?'),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupView(), //cambio para ver recuerdo 
                            ),
                          );
                        },
                  child: const Text('Regístrate aquí'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
