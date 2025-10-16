// lib/data/repositories/session_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_session.dart';
import '../models/user.dart';
import '../models/memory.dart';
import '../models/wishlist.dart';
import '../models/playlist.dart';

class SessionRepository {
  final SupabaseClient _supabase;

  SessionRepository(this._supabase);

  Future<User> getCurrentUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return User.fromJson(response);
  }

  Future<List<Memory>> getUserMemories(String userId) async {
    final response = await _supabase
        .from('memory_users')
        .select('''
          memory:memories(*),
          role
        ''')
        .eq('user_id', userId);

    final memories = (response as List).map((item) {
      final memory = Memory.fromJson(item['memory']);
      memory.participants.add(
        UserRole(
          user: User.fromJson({'id': userId}),
          role: MemoryRole.values.firstWhere(
            (e) => e.toString().split('.').last == item['role'],
            orElse: () => MemoryRole.guest,
          ),
        ),
      );
      return memory;
    }).toList();

    return memories;
  }

  Future<List<Wishlist>> getUserWishlists(String userId) async {
    final response = await _supabase
        .from('wishlists')
        .select('''
          *,
          creator:users(*)
        ''')
        .eq('user_id', userId);

    return response.map((json) => Wishlist.fromJson(json)).toList();
  }

  Future<List<Playlist>> getUserPlaylists(String userId) async {
    final response = await _supabase
        .from('playlists')
        .select('''
          *,
          creator:users(*)
        ''')
        .eq('user_id', userId);

    return response.map((json) => Playlist.fromJson(json)).toList();
  }

  Future<UserSession> initializeUserSession(String userId) async {
    final user = await getCurrentUserProfile(userId);
    return UserSession(user: user);
  }

  Future<UserSession> loadFullUserSession(String userId) async {
    final user = await getCurrentUserProfile(userId);
    final memories = await getUserMemories(userId);
    final wishlists = await getUserWishlists(userId);
    final playlists = await getUserPlaylists(userId);

    return UserSession(
      user: user,
      memories: memories,
      wishlists: wishlists,
      playlists: playlists,
    );
  }
}
