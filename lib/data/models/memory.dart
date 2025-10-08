import 'user.dart';
import 'media.dart';
import 'comment.dart';
import 'reaction.dart';
import 'wishlist.dart';

class Memory {
  final int id;
  final String title;
  final String? description;
  final GeoPoint? location;
  final DateTime happenedAt;
  final DateTime createdAt;
  DateTime updatedAt;

  List<UserRole> participants = [];
  List<Media> media = [];
  List<Comment> comments = [];
  List<Reaction> reactions = [];

  Memory({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.happenedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}

class UserRole {
  final User user;
  final MemoryRole role;

  UserRole({required this.user, required this.role});
}

enum MemoryRole { creator, participant, guest }
