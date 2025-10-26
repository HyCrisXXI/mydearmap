import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'user_relation_repository.dart';
import '../models/user.dart';
import '../../core/utils/supabase_setup.dart';
import '../models/user_relation.dart';

class UserRelationRepositoryImpl implements UserRelationRepository {
  final _supabase = SupabaseSetup.client;

  @override
  Future<void> createUserRelation(
    User user,
    User relatedUser,
    String relationType,
  ) async {
    try {
      await _supabase.from('user_relation').insert({
        'user': user,
        'related_user': relatedUser,
        'relation_type': relationType,
      });
    } catch (e) {
      throw AuthException('Error al crear la relación: $e');
    }
  }

  @override
  Future<void> deleteUserRelation(
    User user,
    User relatedUser,
    String relationType,
  ) async {
    try {
      await _supabase.from('user_relation').delete().eq(
        'user',
        user,
      ).eq('related_user', relatedUser).eq('relation_type', relationType);
    } catch (e) {
      throw AuthException('Error al eliminar la relación: $e');
    }
  }
  @override
  Future<List<UserRelation>> getRelationsForUser(String userId) async {
    try {
      final res = await _supabase
          .from('user_relations')
          .select('*, related_user:users(*)')
          .eq('user_id', userId);

      final rows = res as List<dynamic>;
      return rows
          .map((r) => UserRelation.fromMapWithRelated(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener relaciones: $e');
    }
  }

}
