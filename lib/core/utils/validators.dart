// lib/core/utils/validators.dart
class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  static bool isValidName(String name) {
    final trimmedName = name.trim();
    return trimmedName.isNotEmpty &&
        trimmedName.length >= 2 &&
        trimmedName.length <= 50;
  }

  static bool isValidNumber(String number) {
    if (number.isEmpty) return true;
    final numberRegex = RegExp(r'^[+]?[\d\s\-\(\)]{8,15}$');
    return numberRegex.hasMatch(number.trim());
  }

  static bool isValidPassword(String password) {
    final trimmedPassword = password.trim();
    return trimmedPassword.length >= 6;
  }

  static bool isValidBirthDate(String date) {
    if (date.isEmpty) return true;
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();
      final minDate = DateTime(now.year - 120, now.month, now.day);

      return birthDate.isAfter(minDate) && birthDate.isBefore(now);
    } catch (e) {
      return false;
    }
  }

  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    if (!isValidEmail(value)) {
      return 'Por favor ingresa un email válido';
    }
    return null;
  }

  static String? nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    if (!isValidName(value)) {
      return 'El nombre debe tener entre 2 y 50 caracteres';
    }
    return null;
  }

  static String? numberValidator(String? value) {
    if (value != null && value.isNotEmpty && !isValidNumber(value)) {
      return 'Por favor ingresa un número de teléfono válido';
    }
    return null;
  }

  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (!isValidPassword(value)) {
      return 'Debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? birthDateValidator(String? value) {
    if (value != null && value.isNotEmpty && !isValidBirthDate(value)) {
      return 'Por favor ingresa una fecha válida (DD/MM/AAAA)';
    }
    return null;
  }
}
