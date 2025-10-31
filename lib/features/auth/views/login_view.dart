// lib/features/auth/views/login_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/features/auth/controllers/autosuggestion_controller.dart';
import 'package:mydearmap/features/auth/controllers/login_view_model.dart';

import 'signup_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  late AutosuggestionController _emailController;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final initialSuggestionStyle = TextStyle(
      fontSize: 16,
      color: Colors.grey.withAlpha(153),
    );

    _emailController = AutosuggestionController(
      initialSuggestion: '',
      initialSuggestionStyle: initialSuggestionStyle,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ref.read(loginViewModelProvider.notifier).signIn();
  }

  void _syncControllers(LoginViewState state) {
    if (_emailController.text != state.emailInput) {
      _emailController.value = TextEditingValue(
        text: state.emailInput,
        selection: TextSelection.collapsed(offset: state.emailInput.length),
      );
    }

    if (_passwordController.text != state.password) {
      _passwordController.value = TextEditingValue(
        text: state.password,
        selection: TextSelection.collapsed(offset: state.password.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginViewState>(loginViewModelProvider, (prev, next) {
      if (!mounted) return;
      if (prev?.snackbarKey != next.snackbarKey &&
          next.snackbarMessage != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.snackbarMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(loginViewModelProvider.notifier).clearSnackbar();
      }
    });

    final loginState = ref.watch(loginViewModelProvider);
    final loginNotifier = ref.read(loginViewModelProvider.notifier);

    _syncControllers(loginState);

    final theme = Theme.of(context);

    final baseTextStyle = TextStyle(
      fontSize: 16,
      color: theme.colorScheme.onSurface,
    );

    final suggestionStyle = baseTextStyle.copyWith(
      color: theme.colorScheme.onSurface.withAlpha(89),
    );

    _emailController
      ..suggestionStyle = suggestionStyle
      ..suggestion = loginState.domainSuggestion;

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
                errorText: loginState.emailError,
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: loginNotifier.onEmailChanged,
              onSubmitted: (_) => _signIn(),
              style: baseTextStyle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                errorText: loginState.passwordError,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    loginState.obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: loginNotifier.togglePasswordVisibility,
                ),
              ),
              obscureText: loginState.obscurePassword,
              onChanged: loginNotifier.onPasswordChanged,
              onSubmitted: (_) => _signIn(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loginState.canSubmit ? _signIn : null,
                child: loginState.isSubmitting
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
                  onPressed: loginState.isSubmitting
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
