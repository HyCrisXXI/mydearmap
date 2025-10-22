// lib/core/providers/current_user_provider.dart
import 'package:mydearmap/data/repositories/user_repository.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

final currentUserProvider = FutureProvider<User?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  final userRepository = ref.read(userRepositoryProvider);
  try {
    final userProfile = await userRepository.fetchUserProfile(user.id);
    return userProfile;
  } catch (e) {
    return null;
  }
});
