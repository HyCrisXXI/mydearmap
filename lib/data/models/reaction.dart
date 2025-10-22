// lib/data/models/reaction.dart
import 'user.dart';

class Reaction {
  final int id;
  final User user;
  final String reactionType;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.user,
    required this.reactionType,
    required this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as int,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      reactionType: json['reaction_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'reaction_type': reactionType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
