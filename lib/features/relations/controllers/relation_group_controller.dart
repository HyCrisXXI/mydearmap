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

  Future<void> updateGroupImage({
    required String currentUserId,
    required String groupId,
    required Uint8List bytes,
    String? filename,
  }) async {
    state = const AsyncValue.loading();
    try {
      final photoFileName = await _repository.uploadGroupPhoto(
        creatorId: currentUserId,
        bytes: bytes,
        filename: filename,
      );
      await _repository.updateGroup(
        groupId: groupId,
        photoFileName: photoFileName,
      );

      ref.invalidate(userRelationGroupsProvider(currentUserId));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteGroup({
    required String groupId,
    required String currentUserId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteGroup(groupId: groupId);
      ref.invalidate(userRelationGroupsProvider(currentUserId));
      state = const AsyncValue.data(null);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateGroup({
    required String groupId,
    required String creatorId,
    String? name,
    Uint8List? photoBytes,
    String? photoFilename,
    List<String>? memberIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      String? photoFileName;
      if (photoBytes != null && photoBytes.isNotEmpty) {
        photoFileName = await _repository.uploadGroupPhoto(
          creatorId: creatorId,
          bytes: photoBytes,
          filename: photoFilename,
        );
      }

      await _repository.updateGroup(
        groupId: groupId,
        name: name,
        photoFileName: photoFileName,
      );

      if (memberIds != null) {
        await _repository.updateGroupMembers(
          groupId: groupId,
          memberIds: memberIds,
          creatorId: creatorId,
        );
      }

      ref.invalidate(userRelationGroupsProvider(creatorId));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
