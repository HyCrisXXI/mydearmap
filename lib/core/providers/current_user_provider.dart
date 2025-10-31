// lib/core/providers/current_user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

final _authUserIdProvider = StreamProvider<String?>((ref) {
  final client = Supabase.instance.client;
  return client.auth.onAuthStateChange.map((event) {
    final session = event.session;
    return session?.user.id;
  });
});

final currentUserProvider = FutureProvider.autoDispose<User?>((ref) async {
  final authUserIdState = ref.watch(_authUserIdProvider);

  final authUserId = authUserIdState.maybeWhen(
    data: (id) => id,
    orElse: () => Supabase.instance.client.auth.currentUser?.id,
  );

  if (authUserId == null) {
    return null;
  }

  final userRepository = ref.watch(userRepositoryProvider);

  try {
    final userProfile = await userRepository.fetchUserProfile(authUserId);
    return userProfile;
  } catch (_) {
    return null;
  }
});
