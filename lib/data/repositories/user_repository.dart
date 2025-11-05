// lib/data/repositories/user_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../../core/utils/supabase_setup.dart';

class UserRepository {
  final SupabaseClient _supabase;

  UserRepository(this._supabase);

  Future<User> fetchUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return User.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception('Perfil de usuario no encontrado en la base de datos.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? number,
    DateTime? birthDate,
    String? gender,
    String? profileUrl,
  }) async {
    try {
      if (email != null) {
        try {
          await _supabase.auth.updateUser(UserAttributes(email: email));
        } on AuthException catch (e) {
          // Manejar el error específico de rate limit
          if (e.message.contains('security purposes') ||
              e.message.contains('10 seconds')) {
            throw Exception(
              'Por seguridad, solo puedes cambiar el email cada 10 segundos.',
            );
          }
          throw Exception('Error al actualizar el email: ${e.message}');
        }
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;

      updateData['number'] = number;

      if (birthDate != null) {
        updateData['birth_date'] = birthDate.toIso8601String();
      }
      if (gender != null) updateData['gender'] = gender;
      if (profileUrl != null) updateData['profile_url'] = profileUrl;

      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return User.fromJson(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al actualizar el perfil: $e');
    }
  }
}

final userRepositoryProvider = Provider((ref) {
  return UserRepository(SupabaseSetup.client);
});
