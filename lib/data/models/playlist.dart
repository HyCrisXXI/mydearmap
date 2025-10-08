import 'user.dart';
import 'memory.dart';

class Playlist {
  final int id;
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
}

class MemoryEntry {
  final Memory memory;
  final int position;

  MemoryEntry({required this.memory, required this.position});
}
