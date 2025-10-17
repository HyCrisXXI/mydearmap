// lib/core/errors/auth_errors.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AppAuthException implements Exception {
  final String message;
  final String code;

  AppAuthException(this.message, {this.code = 'unknown'});

  @override
  String toString() => message;

  factory AppAuthException.invalidCredentials() {
    return AppAuthException(
      'Email o contraseña incorrectos. Por favor verifica tus credenciales.',
      code: 'invalid_credentials',
    );
  }

  factory AppAuthException.emailInUse() {
    return AppAuthException(
      'Este email ya está registrado. ¿Quieres iniciar sesión?',
      code: 'email_in_use',
    );
  }

  factory AppAuthException.networkError() {
    return AppAuthException(
      'Error de conexión. Por favor verifica tu internet.',
      code: 'network_error',
    );
  }

  factory AppAuthException.weakPassword() {
    return AppAuthException(
      'La contraseña es demasiado débil. Debe tener al menos 6 caracteres.',
      code: 'weak_password',
    );
  }

  factory AppAuthException.invalidEmail() {
    return AppAuthException(
      'Por favor ingresa un email válido.',
      code: 'invalid_email',
    );
  }

  factory AppAuthException.rateLimit() {
    return AppAuthException(
      'Demasiados intentos. Por favor espera 30 segundos.',
      code: 'rate_limit',
    );
  }

  factory AppAuthException.fromSupabase(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return AppAuthException.invalidCredentials();
      case 'User already registered':
        return AppAuthException.emailInUse();
      case 'Email rate limit exceeded':
        return AppAuthException.rateLimit();
      case 'Weak password':
        return AppAuthException.weakPassword();
      default:
        return AppAuthException('Error de autenticación: ${e.message}');
    }
  }
}
