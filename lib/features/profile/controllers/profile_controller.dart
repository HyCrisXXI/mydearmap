import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/repositories/user_repository.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(() {
      return ProfileController();
    });

class ProfileController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? number,
    DateTime? birthDate,
    String? gender,
    String? profileUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(userRepositoryProvider);
      await repository.updateUserProfile(
        userId: userId,
        name: name,
        email: email,
        number: number,
        birthDate: birthDate,
        gender: gender,
        profileUrl: profileUrl,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
