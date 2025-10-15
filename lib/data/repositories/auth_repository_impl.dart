import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'auth_repository.dart';
import '../models/user.dart';
import '../../core/utils/supabase_setup.dart';

class AuthRepositoryImpl implements AuthRepository {
  final _supabase = SupabaseSetup.client;

  @override
  Stream<User?> get currentUser {
    return _supabase.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;

      // Mapear el usuario de Supabase a tu modelo User
      return User(
        id: user.id,
        name:
            user.userMetadata?['name'] ??
            user.email?.split('@').first ??
            'Usuario',
        email: user.email!,
        gender: Gender.other, // Valor por defecto
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  Future<void> signInWithOtp(String email) async {
    try {
      final response = await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo:
            'mi-app://login-callback', // Para deep linking en apps nativas
      );
      // No necesitas hacer nada más aquí. Supabase se encarga de enviar el email.
    } catch (e) {
      throw AuthException('Error al enviar el código OTP: $e');
    }
  }

  @override
  Future<void> verifyOtp(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );

      if (response.user != null) {
        final isNewUser = response.session?.user?.identities?.isEmpty ?? true;

        if (isNewUser) {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'name':
                response.user?.userMetadata?['name'] ?? email.split('@').first,
            'email': email,
            'gender': 'other',
          });
        }
      }
    } catch (e) {
      throw AuthException('Código OTP inválido o expirado: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
