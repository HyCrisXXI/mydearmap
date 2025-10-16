// lib/data/models/playlist.dart
import 'user.dart';
import 'memory.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  DateTime updatedAt;

  final User creator;
  List<MemoryEntry> memories = [];

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.creator,
  });
  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creator: User.fromJson(json['creator']),
    );
  }
}

class MemoryEntry {
  final Memory memory;
  final int position;

  MemoryEntry({required this.memory, required this.position});
}
