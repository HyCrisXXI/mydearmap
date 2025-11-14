// lib/data/models/user_relation.dart
import 'user.dart';

class UserRelation {
  final User user;
  final User relatedUser;
  final String relationType;
  final String color;

  UserRelation({
    required this.user,
    required this.relatedUser,
    required this.relationType,
    required this.color,
  });
  factory UserRelation.fromMapWithRelated(Map<String, dynamic> map) {
    final userMap = map['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['user'] as Map)
        : null;
    final relatedMap = map['related_user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(map['related_user'] as Map)
        : null;

    final user = (userMap != null && userMap.isNotEmpty)
        ? User.fromMap(userMap)
        : User.fromMap({'id': map['user_id'] ?? map['user'] ?? ''});

    final relatedUser = (relatedMap != null && relatedMap.isNotEmpty)
        ? User.fromMap(relatedMap)
        : User.fromMap({
            'id': map['related_user_id'] ?? map['related_user'] ?? '',
          });

    return UserRelation(
      user: user,
      relatedUser: relatedUser,
      relationType: (map['relation_type'] ?? '').toString(),
      color: (map['color'] ?? '').toString(),
    );
  }
}
