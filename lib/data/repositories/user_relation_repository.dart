import '../models/user.dart';
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
}