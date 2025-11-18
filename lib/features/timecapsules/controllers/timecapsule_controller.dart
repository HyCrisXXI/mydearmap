import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/repositories/timecapsule_repository.dart';
import 'package:mydearmap/data/models/timecapsule.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/memory.dart';

final timeCapsuleControllerProvider =
    AsyncNotifierProvider<TimeCapsuleController, void>(
      () => TimeCapsuleController(),
    );

class TimeCapsuleController extends AsyncNotifier<void> {
  late TimeCapsuleRepository _repository;

  @override
  Future<void> build() async {
    _repository = ref.watch(timeCapsuleRepositoryProvider);
  }

  Future<List<TimeCapsule>> getUserTimeCapsules(String userId) async {
    return _repository.getUserTimeCapsules(userId);
  }

  Future<TimeCapsule?> getTimeCapsuleById(String id) async {
    return _repository.getTimeCapsuleById(id);
  }

  Future<List<Memory>> getTimeCapsuleMemories(String capsuleId) async {
    return _repository.getTimeCapsuleMemories(capsuleId);
  }

  Future<void> openTimeCapsule(String capsuleId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.openTimeCapsule(capsuleId);
      ref.invalidate(timeCapsuleProvider(capsuleId));
      ref.invalidate(userTimeCapsulesProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<TimeCapsule> createTimeCapsule({
    required String creatorId,
    required String title,
    String? description,
    required DateTime openAt,
    required List<String> memoryIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final params = CreateTimeCapsuleParams(
        creatorId: creatorId,
        title: title,
        description: description,
        openAt: openAt,
        memoryIds: memoryIds,
      );
      final capsule = await ref.read(createTimeCapsuleProvider(params).future);
      ref.invalidate(userTimeCapsulesProvider);
      ref.invalidate(userMemoriesProvider); // Refresh cache
      ref.invalidate(timeCapsuleMemoriesProvider); // <- Añadido
      state = const AsyncValue.data(null);
      return capsule;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<TimeCapsule> updateTimeCapsule({
    required String capsuleId,
    required String title,
    String? description,
    required DateTime openAt,
    required List<String> memoryIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final params = UpdateTimeCapsuleParams(
        capsuleId: capsuleId,
        title: title,
        description: description,
        openAt: openAt,
        memoryIds: memoryIds,
      );
      final capsule = await ref.read(updateTimeCapsuleProvider(params).future);
      ref.invalidate(timeCapsuleProvider(capsuleId));
      ref.invalidate(userTimeCapsulesProvider);
      ref.invalidate(userMemoriesProvider); // Refresh cache
      ref.invalidate(timeCapsuleMemoriesProvider); // <- Añadido
      state = const AsyncValue.data(null);
      return capsule;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
