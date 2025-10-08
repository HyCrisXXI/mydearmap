import 'user.dart';

class Comment {
  final int id;
  final User user;
  final String content;
  final DateTime createdAt;
  DateTime updatedAt;

  Comment({
    required this.id,
    required this.user,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}
