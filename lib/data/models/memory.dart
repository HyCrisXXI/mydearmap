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
    final memory = Memory(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] != null
          ? GeoPoint.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      happenedAt: DateTime.parse(json['happened_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

    if (json['participants'] != null) {
      memory.participants = (json['participants'] as List)
          .map((p) => UserRole(
                user: User.fromJson(p['user'] as Map<String, dynamic>),
                role: MemoryRole.values.firstWhere(
                  (r) => r.name == (p['role'] as String),
                  orElse: () => MemoryRole.guest,
                ),
              ))
          .toList();
    }

    
    if (json['media'] != null) {
      memory.media = (json['media'] as List)
          .map((m) => Media.fromJson(m as Map<String, dynamic>))
          .toList();
    }
  
    if (json['comments'] != null) {
      memory.comments = (json['comments'] as List)
          .map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    
    if (json['reactions'] != null) {
      memory.reactions = (json['reactions'] as List)
          .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return memory;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location != null
          ? {
              'type': 'Point',
              'coordinates': [location!.longitude, location!.latitude],
            }
          : null,
      'happened_at': happenedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (participants.isNotEmpty)
        'participants': participants
            .map((p) => {
                  'user': p.user.toJson(),
                  'role': p.role.name,
                })
            .toList(),
      if (media.isNotEmpty)
        'media': media.map((m) => m.toJson()).toList(),
      if (comments.isNotEmpty)
        'comments': comments.map((c) => c.toJson()).toList(),
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
