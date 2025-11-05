// lib/features/auth/controllers/signup_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/errors/auth_errors.dart';
import 'package:mydearmap/core/utils/form_validation_mixin.dart';
import 'package:mydearmap/core/utils/validators.dart';
import 'package:mydearmap/features/auth/controllers/auth_controller.dart';
import 'package:mydearmap/features/auth/controllers/signup_controller.dart';
import 'package:mydearmap/features/auth/models/form_cache.dart';
import 'package:mydearmap/features/auth/models/signup_form_state.dart';

class SignupViewState {
  final SignupFormState form;
  final String? emailError;
  final String? passwordError;
  final String? nameError;
  final String? numberError;
  final String? birthDateError;
  final DateTime? birthDate;
  final bool obscurePassword;
  final bool isSubmitting;
  final String? snackbarMessage;
  final int snackbarKey;

  const SignupViewState({
    this.form = const SignupFormState(),
    this.emailError,
    this.passwordError,
    this.nameError,
    this.numberError,
    this.birthDateError,
    this.birthDate,
    this.obscurePassword = true,
    this.isSubmitting = false,
    this.snackbarMessage,
    this.snackbarKey = 0,
  });

  bool get canSubmit =>
      !isSubmitting &&
      form.email.isNotEmpty &&
      form.password.isNotEmpty &&
      form.name.isNotEmpty &&
      emailError == null &&
      passwordError == null &&
      nameError == null &&
      numberError == null &&
      birthDateError == null;

  String get birthDateDisplay {
    final date = birthDate;
    if (date == null) {
      return '';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static const Object _useExisting = Object();

  SignupViewState copyWith({
    SignupFormState? form,
    Object? emailError = _useExisting,
    Object? passwordError = _useExisting,
    Object? nameError = _useExisting,
    Object? numberError = _useExisting,
    Object? birthDateError = _useExisting,
    Object? birthDate = _useExisting,
    bool? obscurePassword,
    bool? isSubmitting,
    Object? snackbarMessage = _useExisting,
    int? snackbarKey,
  }) {
    return SignupViewState(
      form: form ?? this.form,
      emailError: emailError == _useExisting
          ? this.emailError
          : emailError as String?,
      passwordError: passwordError == _useExisting
          ? this.passwordError
          : passwordError as String?,
      nameError: nameError == _useExisting
          ? this.nameError
          : nameError as String?,
      numberError: numberError == _useExisting
          ? this.numberError
          : numberError as String?,
      birthDateError: birthDateError == _useExisting
          ? this.birthDateError
          : birthDateError as String?,
      birthDate: birthDate == _useExisting
          ? this.birthDate
          : birthDate as DateTime?,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      snackbarMessage: snackbarMessage == _useExisting
          ? this.snackbarMessage
          : snackbarMessage as String?,
      snackbarKey: snackbarKey ?? this.snackbarKey,
    );
  }
}

class SignupViewModel extends Notifier<SignupViewState>
    with FormValidationMixin {
  @override
  SignupViewState build() {
    return const SignupViewState();
  }

  void onNameChanged(String value) {
    state = state.copyWith(
      form: state.form.copyWith(name: value),
      nameError: validateName(value),
    );
  }

  void onEmailChanged(String value) {
    state = state.copyWith(
      form: state.form.copyWith(email: value),
      emailError: validateEmail(value),
    );
  }

  void onPasswordChanged(String value) {
    state = state.copyWith(
      form: state.form.copyWith(password: value),
      passwordError: validatePassword(value),
    );
  }

  void onNumberChanged(String value) {
    state = state.copyWith(
      form: state.form.copyWith(number: value.isEmpty ? null : value),
      numberError: validatePhoneNumber(value),
    );
  }

  void onGenderChanged(String? value) {
    ref.read(signupFormProvider.notifier).updateGender(value);
    state = state.copyWith(form: state.form.copyWith(gender: value));
  }

  void onBirthDateSelected(DateTime date) {
    final isoDate = _formatIsoDate(date);
    ref.read(signupFormProvider.notifier).updateBirthDate(isoDate);
    final display = _formatDisplayDate(date);
    final error = Validators.birthDateValidator(display);
    state = state.copyWith(
      form: state.form.copyWith(birthDate: isoDate),
      birthDate: date,
      birthDateError: error,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<bool> submit() async {
    if (state.isSubmitting) return false;

    final form = state.form;
    final emailError = Validators.emailValidator(form.email);
    final passwordError = Validators.passwordValidator(form.password);
    final nameError = Validators.nameValidator(form.name);
    final numberError = Validators.numberValidator(form.number);
    final birthDateError = Validators.birthDateValidator(
      state.birthDateDisplay,
    );

    state = state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
      nameError: nameError,
      numberError: numberError,
      birthDateError: birthDateError,
    );

    if ([
      emailError,
      passwordError,
      nameError,
      numberError,
      birthDateError,
    ].any((error) => error != null)) {
      return false;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      await ref.read(authControllerProvider.notifier).signUp(form);
      FormErrorCache.clearCache();
      ref.read(signupFormProvider.notifier).clear();
      state = state.copyWith(
        isSubmitting: false,
        form: const SignupFormState(),
        birthDate: null,
        emailError: null,
        passwordError: null,
        nameError: null,
        numberError: null,
        birthDateError: null,
      );
      return true;
    } on AppAuthException catch (e) {
      _emitError(form.email, form.password, e.message);
    } catch (e) {
      final message = 'Error al registrar: ${e.toString()}';
      _emitError(form.email, form.password, message);
    }

    return false;
  }

  void clearSnackbar() {
    if (state.snackbarMessage != null) {
      state = state.copyWith(snackbarMessage: null);
    }
  }

  void _emitError(String email, String password, String rawMessage) {
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

  String _formatIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatDisplayDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

final signupViewModelProvider =
    NotifierProvider<SignupViewModel, SignupViewState>(SignupViewModel.new);
