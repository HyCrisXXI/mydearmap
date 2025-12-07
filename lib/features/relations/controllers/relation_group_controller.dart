import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/relation_groups_provider.dart';
import 'package:mydearmap/data/repositories/relation_group_repository.dart';

final relationGroupControllerProvider =
    AsyncNotifierProvider<RelationGroupController, void>(() {
  return RelationGroupController();
});

class RelationGroupController extends AsyncNotifier<void> {
  RelationGroupRepository get _repository =>
      ref.read(relationGroupRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> createGroup({
    required String creatorId,
    required String name,
    Uint8List? photoBytes,
    String? photoFilename,
    List<String> memberIds = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createGroup(
        creatorId: creatorId,
        name: name,
        photoBytes: photoBytes,
        photoFilename: photoFilename,
        memberIds: memberIds,
      );

      ref.invalidate(userRelationGroupsProvider(creatorId));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
