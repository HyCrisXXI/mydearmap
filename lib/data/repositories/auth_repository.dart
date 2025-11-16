// lib/data/repositories/auth_repository.dart
import 'package:mydearmap/core/utils/supabase_setup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<String> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null,
      );

      final user = response.user;
      if (user == null) {
        throw AuthException('Error al crear la cuenta');
      }

      return user.id;
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('already registered') ||
          message.contains('user with this email address already exists')) {
        throw AuthException(
          'El email ya está registrado. Por favor, inicia sesión.',
        );
      }
      throw AuthException('Error en el registro: ${e.message}');
    } catch (e) {
      throw AuthException('Error en el registro: $e');
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        throw AuthException('Email o contraseña incorrectos.');
      }
      throw AuthException('Error en el inicio de sesión: ${e.message}');
    } catch (e) {
      throw AuthException('Error en el inicio de sesión: $e');
    }
  }

  Future<void> createUserProfile(Map<String, dynamic> profileData) async {
    try {
      await _supabase.from('users').insert(profileData);
    } catch (e) {
      throw AuthException('Error al crear el perfil: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut(scope: SignOutScope.global);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(SupabaseSetup.client);
});
