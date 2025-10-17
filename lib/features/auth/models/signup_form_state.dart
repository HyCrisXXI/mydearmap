// lib/features/auth/models/signup_form_state.dart
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
      password: password ?? this.password,
      name: name ?? this.name,
      number: number ?? this.number,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
    );
  }
}
