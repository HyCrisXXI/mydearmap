import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mydearmap/data/models/achievements.dart';

class AchievementRepository {
  AchievementRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<UserAchievement>> fetchUserAchievements(String userId) async {
    if (userId.isEmpty) return const [];
    final dynamic response = await _client
        .from('user_achievements')
        .select('*, achievements(*)')
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);
    if (response is! List) return const [];
    return response
        .map((row) => UserAchievement.fromMap(row as Map<String, dynamic>))
        .toList();
  }
}
