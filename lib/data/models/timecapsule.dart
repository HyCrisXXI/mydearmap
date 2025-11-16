import 'user.dart';

class TimeCapsule {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final DateTime openAt;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime updatedAt;

  final User? creator;

  TimeCapsule({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.openAt,
    required this.isOpen,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
  });

  factory TimeCapsule.fromMap(Map<String, dynamic> map) {
    return TimeCapsule(
      id: (map['id'] ?? '').toString(),
      creatorId: (map['creator_id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: map['description'] as String?,
      openAt: map['open_at'] != null
          ? DateTime.tryParse(map['open_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isOpen: map['is_open'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      creator: map['users'] != null
          ? User.fromMap(map['users'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'open_at': openAt.toIso8601String(),
      'is_open': isOpen,
    };
  }

  int get daysUntilOpen {
    final now = DateTime.now();
    final difference = openAt.difference(now);
    return difference.inDays > 0 ? difference.inDays : 0;
  }

  bool get isClosed => !isOpen && openAt.isAfter(DateTime.now());
}
