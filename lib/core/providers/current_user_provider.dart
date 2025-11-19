// lib/core/providers/current_user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

final currentUserProvider = FutureProvider<User?>((ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return null;

  final userRepository = ref.watch(userRepositoryProvider);

  try {
    final userProfile = await userRepository.fetchUserProfile(session.user.id);
    return userProfile;
  } catch (_) {
    return null;
  }
});
