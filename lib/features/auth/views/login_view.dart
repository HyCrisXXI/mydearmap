// lib/features/auth/views/login_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/features/auth/controllers/autosuggestion_controller.dart';
import 'package:mydearmap/features/auth/controllers/login_view_model.dart';
import 'package:mydearmap/core/widgets/app_form_buttons.dart';
import 'package:mydearmap/core/constants/constants.dart';

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('MyDearMap', style: AppTextStyles.title),
                const SizedBox(height: 60),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Iniciar sesión', style: AppTextStyles.title),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: loginState.emailError,
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
                    errorText: loginState.passwordError,
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
                const SizedBox(height: 60),
                AppFormButtons(
                  primaryLabel: 'Iniciar sesión',
                  onPrimaryPressed: loginState.canSubmit ? _signIn : null,
                  isProcessing: loginState.isSubmitting,
                  secondaryLabel: 'Registrarse',
                  onSecondaryPressed: loginState.isSubmitting
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupView(),
                            ),
                          );
                        },
                  secondaryIsCompact: false,
                  secondaryOutlined: true,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Comienza a guardar recuerdos',
                  style: AppTextStyles.text,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
