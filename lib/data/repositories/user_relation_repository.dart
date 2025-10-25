import '../models/user.dart';
import '../../core/utils/supabase_setup.dart';
import '../models/user_relation.dart';
abstract class UserRelationRepository {
  Future<void> createUserRelation(
    User userId,
    User relatedUserId,
    String relationType,
  );
  Future<void> deleteUserRelation(
    User userId,
    User relatedUserId,
    String relationType,
  );
  Future<List<UserRelation>> getRelationsForUser(String userId);
  
}