// lib/features/auth/controllers/signup_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupFormState {
  final String email;
  final String password;
  final String name;
  final String? number;
  final String? birthDate;
  final String? gender;

  const SignupFormState({
    this.email = '',
    this.password = '',
    this.name = '',
    this.number,
    this.birthDate,
    this.gender,
  });

  SignupFormState copyWith({
    String? email,
    String? password,
    String? name,
    String? number,
    String? birthDate,
    String? gender,
  }) {
    return SignupFormState(
      email: email ?? this.email,
      name: name ?? this.name,
      number: number ?? this.number,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
    );
  }
}

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
    NotifierProvider<SignupFormNotifier, SignupFormState>(
      () => SignupFormNotifier(),
    );
