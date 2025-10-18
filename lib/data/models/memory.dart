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
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as GeoPoint?,
      happenedAt: DateTime.parse(json['happened_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      // reactions: (json['reactions'] as List<dynamic>?)
      //         ?.map((r) => Reaction.fromJson(r as Map<String, dynamic>))
      //         .toList() ??
        // [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'happened_at': happenedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (reactions.isNotEmpty)
        'reactions': reactions.map((r) => r.toJson()).toList(),
    };

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
