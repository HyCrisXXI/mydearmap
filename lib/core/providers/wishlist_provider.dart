import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/data/models/wishlist.dart';
import 'package:mydearmap/data/repositories/wishlist_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(Supabase.instance.client);
});

final userWishlistProvider = FutureProvider.autoDispose<List<Wishlist>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    return const [];
  }

  final repository = ref.watch(wishlistRepositoryProvider);
  return repository.fetchWishlistsForUser(user.id);
});
