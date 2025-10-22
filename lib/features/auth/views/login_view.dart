// lib/features/auth/views/login_view.dart
import 'package:mydearmap/core/utils/validators.dart';
import 'package:mydearmap/core/errors/auth_errors.dart';
import 'package:mydearmap/features/auth/models/form_cache.dart';
import 'package:mydearmap/features/auth/controllers/auth_controller.dart';
import 'package:mydearmap/features/auth/controllers/autosuggestion_controller.dart';
import 'signup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  late AutosuggestionController _emailController;
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignInInProgress = false;

  String _suggestedDomain = '';
  static const String _defaultSuggestion = 'gmail.com';

  @override
  void initState() {
    super.initState();

    final TextStyle initialSuggestionStyle = TextStyle(
      fontSize: 16,
      color: Colors.grey.withAlpha(153),
    );

    _emailController = AutosuggestionController(
      initialSuggestion: '',
      initialSuggestionStyle: initialSuggestionStyle,
    );
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final value = _emailController.text;

    String suggestion = '';
    final atIndex = value.lastIndexOf('@');

    if (atIndex != -1) {
      final domainPart = value.substring(atIndex + 1);

      if (domainPart.isEmpty) {
        suggestion = _defaultSuggestion;
      } else if (_defaultSuggestion.startsWith(domainPart)) {
        suggestion = _defaultSuggestion.substring(domainPart.length);
      }
    }

    if (_suggestedDomain != suggestion) {
      _suggestedDomain = suggestion;

      _emailController.suggestion = _suggestedDomain;
    }

    _validateEmail(value);
  }

  void _validateEmail(String value) {
    String fullEmail = value;
    if (value.contains('@') && _suggestedDomain.isNotEmpty) {
      fullEmail = value + _suggestedDomain;
    }

    setState(() {
      if (value.isNotEmpty) {
        _emailError = Validators.emailValidator(fullEmail);
      } else {
        _emailError = null;
      }
    });
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

    String email = _emailController.text;
    if (_suggestedDomain.isNotEmpty && email.contains('@')) {
      email += _suggestedDomain;
    }

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
    final theme = Theme.of(context);

    final baseTextStyle = TextStyle(
      fontSize: 16,
      color: theme.colorScheme.onSurface,
    );

    final suggestionStyle = baseTextStyle.copyWith(
      color: theme.colorScheme.onSurface.withAlpha(89),
    );

    _emailController.suggestionStyle = suggestionStyle;

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
              onSubmitted: (_) => _signIn(),
              style: baseTextStyle,
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
                              builder: (context) => const SignupView(),
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
