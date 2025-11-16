import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/data/repositories/timecapsule_repository.dart';
import 'package:mydearmap/data/models/timecapsule.dart';
import 'package:mydearmap/data/models/memory.dart';

final timeCapsuleRepositoryProvider = Provider<TimeCapsuleRepository>((ref) {
  return TimeCapsuleRepository();
});

final userTimeCapsulesProvider = FutureProvider<List<TimeCapsule>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) throw Exception('No user logged in');
  final repo = ref.watch(timeCapsuleRepositoryProvider);
  return repo.getUserTimeCapsules(user.id);
});

final timeCapsuleProvider = FutureProvider.family<TimeCapsule?, String>((
  ref,
  capsuleId,
) async {
  final repo = ref.watch(timeCapsuleRepositoryProvider);
  return repo.getTimeCapsuleById(capsuleId);
});

final timeCapsuleMemoriesProvider = FutureProvider.family<List<Memory>, String>(
  (ref, capsuleId) async {
    final repo = ref.watch(timeCapsuleRepositoryProvider);
    return repo.getTimeCapsuleMemories(capsuleId);
  },
);

class CreateTimeCapsuleParams {
  final String creatorId;
  final String title;
  final String? description;
  final DateTime openAt;
  final List<String> memoryIds;

  CreateTimeCapsuleParams({
    required this.creatorId,
    required this.title,
    this.description,
    required this.openAt,
    required this.memoryIds,
  });
}

final createTimeCapsuleProvider =
    FutureProvider.family<TimeCapsule, CreateTimeCapsuleParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(timeCapsuleRepositoryProvider);
      return repo.createTimeCapsule(
        creatorId: params.creatorId,
        title: params.title,
        description: params.description,
        openAt: params.openAt,
        memoryIds: params.memoryIds,
      );
    });

class UpdateTimeCapsuleParams {
  final String capsuleId;
  final String title;
  final String? description;
  final DateTime openAt;
  final List<String> memoryIds;

  UpdateTimeCapsuleParams({
    required this.capsuleId,
    required this.title,
    this.description,
    required this.openAt,
    required this.memoryIds,
  });
}

final updateTimeCapsuleProvider =
    FutureProvider.family<TimeCapsule, UpdateTimeCapsuleParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(timeCapsuleRepositoryProvider);
      return repo.updateTimeCapsule(
        capsuleId: params.capsuleId,
        title: params.title,
        description: params.description,
        openAt: params.openAt,
        memoryIds: params.memoryIds,
      );
    });
