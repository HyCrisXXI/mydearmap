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

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginViewState>(loginViewModelProvider, (prev, next) {
      if (!mounted) return;

      // Sync controllers
      if (_emailController.text != next.emailInput) {
        _emailController.value = TextEditingValue(
          text: next.emailInput,
          selection: TextSelection.collapsed(offset: next.emailInput.length),
        );
      }
      if (_passwordController.text != next.password) {
        _passwordController.value = TextEditingValue(
          text: next.password,
          selection: TextSelection.collapsed(offset: next.password.length),
        );
      }

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
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(AppIcons.authBG, fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 125.0),
                  child: Text('MyDearMap', style: AppTextStyles.myDearMapTitle),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 60.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Iniciar sesión',
                              style: AppTextStyles.title,
                            ),
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
                            style: AppTextStyles.textField,
                          ),
                          const SizedBox(height: 52),
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
                                  color: loginState.passwordError != null
                                      ? theme.colorScheme.error
                                      : AppColors.textColor,
                                ),
                                onPressed:
                                    loginNotifier.togglePasswordVisibility,
                              ),
                            ),
                            obscureText: loginState.obscurePassword,
                            onChanged: loginNotifier.onPasswordChanged,
                            onSubmitted: (_) => _signIn(),
                            style: AppTextStyles.textField,
                          ),
                          const SizedBox(height: 60),
                          AppFormButtons(
                            primaryLabel: 'Iniciar sesión',
                            onPrimaryPressed: loginState.canSubmit
                                ? _signIn
                                : null,
                            isProcessing: loginState.isSubmitting,
                            secondaryLabel: 'Registrarse',
                            onSecondaryPressed: loginState.isSubmitting
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignupView(),
                                      ),
                                    );
                                  },
                            secondaryIsCompact: false,
                            secondaryOutlined: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 150.0),
                  child: Text(
                    'Comienza a guardar recuerdos',
                    style: AppTextStyles.textButton,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
