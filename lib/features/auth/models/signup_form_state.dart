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

  static const Object _useExisting = Object();

  SignupFormState copyWith({
    String? email,
    String? password,
    String? name,
    Object? number = _useExisting,
    Object? birthDate = _useExisting,
    Object? gender = _useExisting,
  }) {
    return SignupFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      number: number == _useExisting ? this.number : number as String?,
      birthDate: birthDate == _useExisting
          ? this.birthDate
          : birthDate as String?,
      gender: gender == _useExisting ? this.gender : gender as String?,
    );
  }
}
