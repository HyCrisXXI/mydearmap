// lib/data/models/comment.dart
import 'user.dart';

class Comment {
  final String id;
  final User user;
  final String content;
  final String? subtitle;
  final DateTime createdAt;
  DateTime updatedAt;

  Comment({
    required this.id,
    required this.user,
    required this.content,
    this.subtitle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      content: json['content'] as String,
      subtitle: (json['subtitle'] ?? json['subtext']) as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'content': content,
      'subtext': subtitle,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
