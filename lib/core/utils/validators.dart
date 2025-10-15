class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidName(String name) {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }

  static bool isValidVerificationCode(String code) {
    return code.length == 6 && RegExp(r'^\d+$').hasMatch(code);
  }

  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email es requerido';
    }
    if (!isValidEmail(value)) {
      return 'Email inválido';
    }
    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contraseña es requerida';
    }
    if (!isValidPassword(value)) {
      return 'Contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nombre es requerido';
    }
    if (!isValidName(value)) {
      return 'Nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  static String? codeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Código es requerido';
    }
    if (!isValidVerificationCode(value)) {
      return 'Código debe ser de 6 dígitos';
    }
    return null;
  }
}
