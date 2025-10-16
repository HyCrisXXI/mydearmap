// lib/data/models/memory.dart
import 'user.dart';
import 'media.dart';
import 'comment.dart';
import 'reaction.dart';

class Memory {
  final String id;
  final String title;
  final String? description;
  final GeoPoint? location;
  final DateTime happenedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

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

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] != null
          ? GeoPoint.fromJson(json['location'])
          : null,
      happenedAt: DateTime.parse(json['happened_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class UserRole {
  final User user;
  final MemoryRole role;

  UserRole({required this.user, required this.role});
}

class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint(this.latitude, this.longitude);

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as List;
    return GeoPoint(coordinates[1] as double, coordinates[0] as double);
  }
}

enum MemoryRole { creator, participant, guest }
