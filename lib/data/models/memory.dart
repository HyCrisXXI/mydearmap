// lib/data/models/memory.dart
import 'user.dart';
import 'media.dart';
import 'comment.dart';
import 'reaction.dart';

class Memory {
  final String? id;
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
    this.id,
    required this.title,
    this.description,
    this.location,
    required this.happenedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Memory copyWith({
    String? id,
    String? title,
    String? description,
    GeoPoint? location,
    DateTime? happenedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<UserRole>? participants,
    List<Media>? media,
    List<Comment>? comments,
    List<Reaction>? reactions,
  }) {
    final newMemory = Memory(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      happenedAt: happenedAt ?? this.happenedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

    newMemory.participants = participants ?? this.participants;
    newMemory.media = media ?? this.media;
    newMemory.comments = comments ?? this.comments;
    newMemory.reactions = reactions ?? this.reactions;

    return newMemory;
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    final locationData = json['location'];
    GeoPoint? parsedLocation;

    if (locationData is Map<String, dynamic>) {
      parsedLocation = GeoPoint.fromJson(locationData);
    }

    final memory = Memory(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: parsedLocation,
      happenedAt: DateTime.parse(json['happened_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

    if (json['participants'] != null) {
      memory.participants = (json['participants'] as List)
          .map((p) {
            final userData = p['user'];
            if (userData == null || userData is! Map<String, dynamic>) {
              return null;
            }
            return UserRole(
              user: User.fromJson(userData),
              role: MemoryRole.values.firstWhere(
                (r) => r.name == (p['role'] as String),
                orElse: () => MemoryRole.guest,
              ),
            );
          })
          .whereType<UserRole>()
          .toList();
    }

    if (json['media'] != null) {
      memory.media = (json['media'] as List)
          .map((m) {
            if (m is! Map<String, dynamic>) return null;
            return Media.fromJson(m);
          })
          .whereType<Media>()
          .toList();
    }

    if (json['comments'] != null) {
      memory.comments = (json['comments'] as List)
          .map((c) {
            if (c is! Map<String, dynamic>) return null;
            return Comment.fromJson(c);
          })
          .whereType<Comment>()
          .toList();
    }

    if (json['reactions'] != null) {
      memory.reactions = (json['reactions'] as List)
          .map((r) {
            if (r is! Map<String, dynamic>) return null;
            return Reaction.fromJson(r);
          })
          .whereType<Reaction>()
          .toList();
    }

    return memory;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location != null
          ? 'POINT(${location!.longitude} ${location!.latitude})'
          : null,
      'happened_at': happenedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MapMemory {
  final String id;
  final String title;
  final GeoPoint? location;

  MapMemory({required this.id, required this.title, this.location});

  factory MapMemory.fromJson(Map<String, dynamic> json) {
    return MapMemory(
      id: json['id'] as String,
      title: json['title'] as String,
      location: json['location'] != null
          ? GeoPoint.fromJson(json['location'] as Map<String, dynamic>)
          : null,
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
    final dynamic coordinatesData = json['coordinates'];

    if (coordinatesData == null || coordinatesData is! List) {
      throw FormatException(
        'GeoPoint JSON is missing or invalid coordinates field.',
      );
    }

    final coordinates = coordinatesData;

    if (coordinates.length < 2 ||
        coordinates[0] is! num ||
        coordinates[1] is! num) {
      throw FormatException(
        'GeoPoint coordinates must contain at least two numbers.',
      );
    }

    return GeoPoint(coordinates[1].toDouble(), coordinates[0].toDouble());
  }
}

enum MemoryRole { creator, participant, guest }
