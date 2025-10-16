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
}

final userRepositoryProvider = Provider((ref) {
  return UserRepository(SupabaseSetup.client);
});
