import 'package:mydearmap/data/models/user.dart';

class RelationGroup {
  RelationGroup({
    required this.id,
    required this.name,
    this.photoUrl,
    this.createdAt,
    this.members = const [],
  });

  final String id;
  final String name;
  final String? photoUrl;
  final DateTime? createdAt;
  final List<User> members;

  factory RelationGroup.fromMap(Map<String, dynamic> map) {
    return RelationGroup(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      photoUrl: map['photo_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      members: const [],
    );
  }

  factory RelationGroup.fromMapWithMembers(Map<String, dynamic> map) {
    final base = RelationGroup.fromMap(map);
    final membersRaw = map['members'];
    final members = <User>[];
    if (membersRaw is List) {
      for (final entry in membersRaw) {
        if (entry is Map<String, dynamic>) {
          if (entry['user'] is Map<String, dynamic>) {
            members.add(User.fromMap(
              Map<String, dynamic>.from(entry['user'] as Map),
            ));
          } else {
            members.add(User.fromMap(entry));
          }
        }
      }
    }
    return base.copyWith(members: members);
  }

  RelationGroup copyWith({
    String? id,
    String? name,
    String? photoUrl,
    DateTime? createdAt,
    List<User>? members,
  }) {
    return RelationGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
    );
  }
}
