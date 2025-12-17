import 'dart:convert';
import 'package:mydearmap/core/constants/constants.dart';
import 'user.dart';

const String _supabaseAchievementsStorageUrl =
    'https://oomglkpxogeiwrrfphon.supabase.co/storage/v1/object/public/media/achievements/';

class Achievement {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final Map<String, dynamic> criteria;
  final DateTime createdAt;

  Achievement({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.criteria,
    required this.createdAt,
  });

  static String? _buildFullIconUrl(String? iconFilename) {
    if (iconFilename == null || iconFilename.isEmpty) {
      return null;
    }
    return '$_supabaseAchievementsStorageUrl$iconFilename';
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> criteriaData = {};
    if (map['criteria'] != null) {
      try {
        // Maneja tanto si 'criteria' es un String JSON o un Map
        criteriaData = (map['criteria'] is Map<String, dynamic>)
            ? map['criteria']
            : jsonDecode(map['criteria'].toString()) as Map<String, dynamic>;
      } catch (_) {
        criteriaData = {};
      }
    }

    return Achievement(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: map['description'] as String?,
      iconUrl: _buildFullIconUrl(map['icon_url'] as String?),
      criteria: criteriaData,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon_url': iconUrl?.split('/').last,
      'criteria': jsonEncode(criteria),
    };
  }

  String get localIconAsset {
    return switch (name) {
      'Coleccionista' => AppIcons.collectionist,
      'Social' => AppIcons.social,
      'Primer Recuerdo' => AppIcons.firstMemory,
      'Comentarista' => AppIcons.commentarist,
      'Historiador' => AppIcons.historian,
      _ => AppIcons.star,
    };
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final Map<String, dynamic> progressData;

  final User? user;
  final Achievement? achievement;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    required this.progressData,
    this.user,
    this.achievement,
  });

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    return UserAchievement(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      achievementId: (map['achievement_id'] ?? '').toString(),

      unlockedAt: map['unlocked_at'] != null
          ? DateTime.tryParse(map['unlocked_at'].toString()) ?? DateTime.now()
          : DateTime.now(),

      progressData: (map['progress_data'] ?? {}) as Map<String, dynamic>,

      user: map['users'] != null
          ? User.fromMap(map['users'] as Map<String, dynamic>)
          : null,

      achievement: map['achievements'] != null
          ? Achievement.fromMap(map['achievements'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'achievement_id': achievementId,
      'progress_data': progressData,
    };
  }
}
