// lib/features/auth/controllers/signup_controller.dart
import 'package:mydearmap/features/auth/models/signup_form_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupFormNotifier extends Notifier<SignupFormState> {
  @override
  SignupFormState build() {
    return const SignupFormState();
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password);
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateNumber(String? number) {
    state = state.copyWith(number: number);
  }

  void updateBirthDate(String? birthDate) {
    state = state.copyWith(birthDate: birthDate);
  }

  void updateGender(String? gender) {
    state = state.copyWith(gender: gender);
  }

  void clear() {
    state = const SignupFormState();
  }
}

final signupFormProvider =
    NotifierProvider<SignupFormNotifier, SignupFormState>(() {
      return SignupFormNotifier();
    });
