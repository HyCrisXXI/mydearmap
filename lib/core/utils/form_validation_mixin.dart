import 'validators.dart';

mixin FormValidationMixin {
  String? validateName(String? value) => Validators.nameValidator(value ?? '');

  String? validateEmail(String? value) =>
      Validators.emailValidator(value ?? '');

  String? validatePassword(String? value) =>
      Validators.passwordValidator(value ?? '');

  String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return Validators.numberValidator(value);
  }

  bool canSubmitForm({
    required String name,
    required String email,
    String? password,
    String? number,
  }) {
    return name.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        validateName(name) == null &&
        validateEmail(email) == null &&
        (password == null || validatePassword(password) == null) &&
        (number == null ||
            number.isEmpty ||
            validatePhoneNumber(number) == null);
  }
}
