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
}
