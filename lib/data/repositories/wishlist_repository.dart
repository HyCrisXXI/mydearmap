import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist.dart';

class WishlistRepository {
  WishlistRepository(this._client);

  final SupabaseClient _client;

  Future<List<Wishlist>> fetchWishlistsForUser(String userId) async {
    final response = await _client
        .from('wishlists')
        .select('*, user:users!wishlists_user_id_fkey(*)')
        .eq('user_id', userId)
        .order('title');

    return (response as List)
        .whereType<Map<String, dynamic>>()
        .map(_mapWishlist)
        .toList();
  }

  Future<Wishlist> createWishlist({
    required String userId,
    required String title,
  }) async {
    final response = await _client
        .from('wishlists')
        .insert({'user_id': userId, 'title': title, 'completed': false})
        .select('*, user:users!wishlists_user_id_fkey(*)')
        .single();

    return _mapWishlist(Map<String, dynamic>.from(response));
  }

  Future<void> deleteWishlist({required String wishlistId}) async {
    await _client.from('wishlists').delete().eq('id', wishlistId);
  }

  Future<void> updateWishlistCompletion({
    required String wishlistId,
    required bool completed,
  }) async {
    await _client
        .from('wishlists')
        .update({'completed': completed})
        .eq('id', wishlistId);
  }

  Wishlist _mapWishlist(Map<String, dynamic> data) {
    final json = Map<String, dynamic>.from(data);
    final userData = json['user'] ?? json['creator'];
    if (userData != null) {
      json['user'] = userData as Map<String, dynamic>;
    } else {
      json['user'] = {
        'id': json['user_id'] ?? '',
        'name': json['user_name'] ?? 'Usuario',
        'email': json['user_email'] ?? 'sin-correo@mydearmap.app',
        'gender': 'other',
        'created_at': DateTime.now().toIso8601String(),
      };
    }

    return Wishlist.fromJson(json);
  }
}
