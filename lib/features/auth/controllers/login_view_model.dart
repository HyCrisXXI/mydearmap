// lib/features/auth/controllers/login_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/errors/auth_errors.dart';
import 'package:mydearmap/core/utils/validators.dart';
import 'package:mydearmap/features/auth/controllers/auth_controller.dart';
import 'package:mydearmap/features/auth/models/form_cache.dart';

class LoginViewState {
  final String emailInput;
  final String domainSuggestion;
  final String? emailError;
  final String password;
  final String? passwordError;
  final bool isSubmitting;
  final bool obscurePassword;
  final String? snackbarMessage;
  final int snackbarKey;

  const LoginViewState({
    this.emailInput = '',
    this.domainSuggestion = '',
    this.emailError,
    this.password = '',
    this.passwordError,
    this.isSubmitting = false,
    this.obscurePassword = true,
    this.snackbarMessage,
    this.snackbarKey = 0,
  });

  bool get canSubmit =>
      !isSubmitting &&
      emailInput.isNotEmpty &&
      password.isNotEmpty &&
      emailError == null &&
      passwordError == null;

  static const Object _useExisting = Object();

  LoginViewState copyWith({
    String? emailInput,
    String? domainSuggestion,
    Object? emailError = _useExisting,
    String? password,
    Object? passwordError = _useExisting,
    bool? isSubmitting,
    bool? obscurePassword,
    Object? snackbarMessage = _useExisting,
    int? snackbarKey,
  }) {
    return LoginViewState(
      emailInput: emailInput ?? this.emailInput,
      domainSuggestion: domainSuggestion ?? this.domainSuggestion,
      emailError: emailError == _useExisting
          ? this.emailError
          : emailError as String?,
      password: password ?? this.password,
      passwordError: passwordError == _useExisting
          ? this.passwordError
          : passwordError as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      snackbarMessage: snackbarMessage == _useExisting
          ? this.snackbarMessage
          : snackbarMessage as String?,
      snackbarKey: snackbarKey ?? this.snackbarKey,
    );
  }
}

class LoginViewModel extends Notifier<LoginViewState> {
  static const String _defaultSuggestion = 'gmail.com';

  @override
  LoginViewState build() => const LoginViewState();

  void onEmailChanged(String value) {
    final suggestion = _computeSuggestion(value);
    final error = value.isEmpty
        ? null
        : Validators.emailValidator(_resolveEmail(value, suggestion));

    state = state.copyWith(
      emailInput: value,
      domainSuggestion: suggestion,
      emailError: error,
    );
  }

  void onPasswordChanged(String value) {
    final error = value.isEmpty ? null : Validators.passwordValidator(value);
    state = state.copyWith(password: value, passwordError: error);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void clearSnackbar() {
    if (state.snackbarMessage != null) {
      state = state.copyWith(snackbarMessage: null);
    }
  }

  Future<void> signIn() async {
    if (state.isSubmitting) return;

    final resolvedEmail = _resolveEmail(
      state.emailInput,
      state.domainSuggestion,
    );
    final emailError = Validators.emailValidator(resolvedEmail);
    final passwordError = Validators.passwordValidator(state.password);

    state = state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
    );

    if (emailError != null || passwordError != null) {
      return;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithPassword(email: resolvedEmail, password: state.password);
      FormErrorCache.clearCache();
      state = state.copyWith(isSubmitting: false);
    } on AppAuthException catch (e) {
      _handleError(resolvedEmail, e.message);
    } catch (e) {
      final message = 'Error: ${e.toString()}';
      _handleError(resolvedEmail, message);
    }
  }

  void _handleError(String email, String rawMessage) {
    final password = state.password;
    final repeated = FormErrorCache.isRepeatedError(
      email,
      password,
      rawMessage,
    );
    final snackbarMessage = repeated
        ? 'Por favor, corrige los datos antes de intentar nuevamente'
        : rawMessage;

    if (!repeated) {
      FormErrorCache.cacheFailedAttempt(email, password, rawMessage);
    }

    state = state.copyWith(
      isSubmitting: false,
      snackbarMessage: snackbarMessage,
      snackbarKey: state.snackbarKey + 1,
    );
  }

  String _computeSuggestion(String value) {
    final atIndex = value.lastIndexOf('@');
    if (atIndex == -1) {
      return '';
    }

    final domainPart = value.substring(atIndex + 1);
    if (domainPart.isEmpty) {
      return _defaultSuggestion;
    }

    if (_defaultSuggestion.startsWith(domainPart)) {
      return _defaultSuggestion.substring(domainPart.length);
    }

    return '';
  }

  String _resolveEmail(String value, String suggestion) {
    final trimmedValue = value.trim();
    if (trimmedValue.contains('@') && suggestion.isNotEmpty) {
      return trimmedValue + suggestion;
    }
    return trimmedValue;
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginViewState>(
  LoginViewModel.new,
);
