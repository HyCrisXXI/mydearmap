
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../data/models/user.dart';
import '../../../core/errors/auth_errors.dart';

final userRelationController = AsyncNotifierProvider<UserRelationController, List<User>>(() {
  return UserRelationController();
});

class UserRelationController extends AsyncNotifier<List<User>> {
  supabase.SupabaseClient get _supabaseClient => supabase.Supabase.instance.client;

  @override
  Future<List<User>> build() async {
    return [];
  }

  Future<void> fetchUserRelation() async {
    state = const AsyncValue.loading();

    try {
      final response = await _supabaseClient.from('users').select();
      final list = (response as List<dynamic>)
          .map<User?>((e) {
            try {
              return User.fromJson(Map<String, dynamic>.from(e as Map<String, dynamic>));
            } catch (_) {
              return null;
            }
          })
          .whereType<User>()
          .toList(growable: false);
      state = AsyncValue.data(list);
    } catch (e) {
      if (e is AppAuthException) {
        state = AsyncValue.error(e, StackTrace.current);
        rethrow;
      }
      state = AsyncValue.error(AppAuthException('Error inesperado: $e'), StackTrace.current);
    }
  }
}
