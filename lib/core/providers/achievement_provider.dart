import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/models/achievements.dart';
import 'package:mydearmap/data/repositories/achievement_repository.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>(
  (ref) => AchievementRepository(),
);

final userAchievementsProvider = FutureProvider.autoDispose
    .family<List<UserAchievement>, String>(
      (ref, userId) async => ref
          .watch(achievementRepositoryProvider)
          .fetchUserAchievements(userId),
    );
