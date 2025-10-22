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

}
