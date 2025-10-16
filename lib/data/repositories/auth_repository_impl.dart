// lib/data/repositories/user_repository_impl.dart
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

      return User(
        id: user.id,
        name:
            user.userMetadata?['name'] ??
            user.email?.split('@').first ??
            'Usuario',
        email: user.email!,
        gender: Gender.other,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<void> signUpWithPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: null,
      );

      if (response.user != null) {
        await createUserProfile(response.user!.id, email);
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains(
            'user with this email address already exists',
          )) {
        throw AuthException(
          'El email ya está registrado. Por favor, inicia sesión.',
        );
      }
      throw AuthException('Error en el registro: ${e.message}');
    } catch (e) {
      throw AuthException('Error en el registro: $e');
    }
  }

  @override
  Future<void> signInWithPassword(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw AuthException('Email o contraseña incorrectos.');
      }
      throw AuthException('Error en el inicio de sesión: ${e.message}');
    } catch (e) {
      throw AuthException('Error en el inicio de sesión: $e');
    }
  }

  @override
  Future<bool> isNewUser(String userId) async {
    try {
      final response = await _supabase.from('users').select().eq('id', userId);
      return response.isEmpty;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<void> createUserProfile(String userId, String email) async {
    try {
      await _supabase.from('users').insert({
        'id': userId,
        'name': email.split('@').first,
        'email': email,
        'gender': 'other',
      });
    } catch (e) {
      throw AuthException('Error al crear el perfil: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
