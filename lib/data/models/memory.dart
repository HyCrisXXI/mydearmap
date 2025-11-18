// lib/data/models/memory.dart
import 'dart:convert';
import 'dart:typed_data';

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
  final bool isFavorite;
  MemoryRole? currentUserRole;

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
    this.isFavorite = false,
    this.currentUserRole,
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
    MemoryRole? currentUserRole,
    bool? isFavorite,
  }) {
    final newMemory = Memory(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      happenedAt: happenedAt ?? this.happenedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      currentUserRole: currentUserRole ?? this.currentUserRole,
    );

    newMemory.participants = participants ?? this.participants;
    newMemory.media = media ?? this.media;
    newMemory.comments = comments ?? this.comments;
    newMemory.reactions = reactions ?? this.reactions;

    return newMemory;
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    final locationData = json['location'];
    final GeoPoint? parsedLocation = GeoPoint.tryParse(locationData);

    final memory = Memory(
      id: json['id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: parsedLocation,
      happenedAt: DateTime.parse(json['happened_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isFavorite: (json['favorite'] as bool?) ?? false,
      currentUserRole: _tryParseRole(json['current_user_role'] as String?),
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

      memory.media.sort((a, b) {
        final aOrder = effectiveMediaOrder(a);
        final bOrder = effectiveMediaOrder(b);
        final orderCompare = aOrder.compareTo(bOrder);
        if (orderCompare != 0) return orderCompare;
        final priorityCompare = mediaTypePriority(
          a.type,
        ).compareTo(mediaTypePriority(b.type));
        if (priorityCompare != 0) return priorityCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
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

    // 'people' legacy field ignored: participants are stored in memory_users

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
      'favorite': isFavorite,
      // Note: do not include 'people' here because the DB may not have that column.
      // Participants are stored in the `memory_users` table and are synchronized
      // separately by the controller/repository.
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

  static GeoPoint? tryParse(dynamic value) {
    if (value == null) return null;
    if (value is GeoPoint) return value;

    if (value is Map<String, dynamic>) {
      if (value.containsKey('coordinates')) {
        try {
          return GeoPoint.fromJson(value);
        } catch (_) {}
      }
      final latValue = value['lat'] ?? value['latitude'];
      final lngValue = value['lng'] ?? value['lon'] ?? value['longitude'];
      if (latValue is num && lngValue is num) {
        return GeoPoint(latValue.toDouble(), lngValue.toDouble());
      }
    }

    if (value is List && value.length >= 2) {
      final first = value[0];
      final second = value[1];
      if (first is num && second is num) {
        // PostGIS arrays are usually [lon, lat]
        return GeoPoint(second.toDouble(), first.toDouble());
      }
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      // Try JSON string first
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        try {
          final decoded = jsonDecode(trimmed);
          return tryParse(decoded);
        } catch (_) {}
      }

      final pointMatch = RegExp(
        r'POINT\s*\(([-+0-9\.]+)\s+([-+0-9\.]+)\)',
        caseSensitive: false,
      ).firstMatch(trimmed);
      if (pointMatch != null) {
        final lon = double.tryParse(pointMatch.group(1)!);
        final lat = double.tryParse(pointMatch.group(2)!);
        if (lat != null && lon != null) {
          return GeoPoint(lat, lon);
        }
      }

      // Handle PostGIS WKB hex strings such as 0101000020E6100000...
      if (_looksLikeWkb(trimmed)) {
        final parsed = _parseWkbPoint(trimmed);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  static bool _looksLikeWkb(String value) {
    if (value.length < 18) return false;
    final cleaned = value.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    return cleaned.startsWith('00') || cleaned.startsWith('01');
  }

  static GeoPoint? _parseWkbPoint(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
      if (cleaned.length < 34) return null;
      final bytes = _hexToBytes(cleaned);
      if (bytes.length < 21) return null;

      final byteData = ByteData.sublistView(bytes);
      final isLittleEndian = byteData.getUint8(0) == 1;
      final endian = isLittleEndian ? Endian.little : Endian.big;

      // Geometry type is stored at offset 1 (4 bytes), ensure it's a point (value 1)
      final rawType = byteData.getUint32(1, endian);
      final hasSrid = (rawType & 0x20000000) != 0;
      final geometryType = rawType & 0x000000FF;
      if (geometryType != 1) return null;

      var offset = 5;
      if (hasSrid) {
        if (bytes.length < offset + 4 + 16) return null;
        // consume SRID (4 bytes)
        offset += 4;
      }

      if (bytes.length < offset + 16) return null;
      final lon = byteData.getFloat64(offset, endian);
      final lat = byteData.getFloat64(offset + 8, endian);
      return GeoPoint(lat, lon);
    } catch (_) {
      return null;
    }
  }

  static Uint8List _hexToBytes(String hex) {
    final cleaned = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    final length = cleaned.length ~/ 2;
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      final byte = cleaned.substring(i * 2, i * 2 + 2);
      bytes[i] = int.parse(byte, radix: 16);
    }
    return bytes;
  }
}

enum MemoryRole { creator, participant, guest }

MemoryRole? _tryParseRole(String? raw) {
  if (raw == null) return null;
  for (final role in MemoryRole.values) {
    if (role.name == raw) return role;
  }
  return null;
}
