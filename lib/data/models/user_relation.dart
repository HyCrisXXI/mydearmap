// lib/data/models/user_relation.dart
import 'user.dart';

class UserRelation {
  final User user;
  final User relatedUser;
  final String relationType;

  UserRelation({
    required this.user,
    required this.relatedUser,
    required this.relationType,
  });
}
