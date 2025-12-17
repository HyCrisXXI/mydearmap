import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/models/relation_group.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

final relationGroupRepositoryProvider = Provider<RelationGroupRepository>((
  ref,
) {
  return RelationGroupRepository(Supabase.instance.client);
});

class RelationGroupRepository {
  RelationGroupRepository(this._client);

  final SupabaseClient _client;
  static const _storageBucket = 'media';
  static const _storageFolder = 'groups';

  Future<List<RelationGroup>> fetchGroups(String userId) async {
    final membershipRaw = await _client
        .from('relation_group_members')
        .select('group_id')
        .eq('user_id', userId);

    final membershipData = _normalizeRaw(membershipRaw);
    if (membershipData == null) return <RelationGroup>[];

    final groupIds = (membershipData as List<dynamic>)
        .map((row) => (row as Map)['group_id'])
        .whereType<dynamic>()
        .map((id) => id.toString())
        .toList();

    if (groupIds.isEmpty) return <RelationGroup>[];

    final formattedIds = groupIds.map((id) => '"$id"').join(',');
    final groupsRaw = await _client
        .from('relation_groups')
        .select()
        .filter('id', 'in', '($formattedIds)');

    final groupsData = _normalizeRaw(groupsRaw);
    if (groupsData == null) return <RelationGroup>[];

    final membersRaw = await _client
        .from('relation_group_members')
        .select('group_id, user:users(*)')
        .filter('group_id', 'in', '($formattedIds)');

    final membersData = _normalizeRaw(membersRaw);
    final membersByGroup = <String, List<User>>{};
    if (membersData is List) {
      for (final entry in membersData) {
        final map = Map<String, dynamic>.from(entry as Map);
        final groupId = map['group_id']?.toString();
        final userMap = map['user'];
        if (groupId == null || userMap == null) continue;
        final user = User.fromMap(Map<String, dynamic>.from(userMap as Map));
        membersByGroup.putIfAbsent(groupId, () => <User>[]).add(user);
      }
    }

    return (groupsData as List<dynamic>).map((row) {
      final group = RelationGroup.fromMap(
        Map<String, dynamic>.from(row as Map),
      );
      return group.copyWith(members: membersByGroup[group.id] ?? const []);
    }).toList();
  }

  Future<RelationGroup> createGroup({
    required String creatorId,
    required String name,
    Uint8List? photoBytes,
    String? photoFilename,
    List<String> memberIds = const [],
  }) async {
    final inserted = await _client
        .from('relation_groups')
        .insert({'name': name, 'photo_url': null, 'creator_id': creatorId})
        .select()
        .single();

    final groupId = inserted['id'].toString();

    // 2. Upload photo if exists, using the new groupId
    String? finalPhotoUrl;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      finalPhotoUrl = await _uploadGroupPhotoBytes(
        groupId: groupId,
        bytes: photoBytes,
      );

      await _client
          .from('relation_groups')
          .update({'photo_url': finalPhotoUrl})
          .eq('id', groupId);

      inserted['photo_url'] = finalPhotoUrl;
    }

    final uniqueMembers = <String>{creatorId, ...memberIds};
    if (uniqueMembers.isNotEmpty) {
      await _client
          .from('relation_group_members')
          .insert(
            uniqueMembers
                .map(
                  (userId) => {
                    'group_id': groupId,
                    'user_id': userId,
                    'role': userId == creatorId ? 'owner' : 'member',
                  },
                )
                .toList(),
          );
    }

    return RelationGroup.fromMap(Map<String, dynamic>.from(inserted as Map));
  }

  Future<void> deleteGroup({required String groupId}) async {
    await _client
        .from('relation_group_members')
        .delete()
        .eq('group_id', groupId);
    await _client.from('relation_groups').delete().eq('id', groupId);
  }

  Future<String> uploadGroupPhoto({
    required String groupId,
    required Uint8List bytes,
    String? filename,
  }) async {
    return _uploadGroupPhotoBytes(groupId: groupId, bytes: bytes);
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? photoFileName,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (photoFileName != null) updates['photo_url'] = photoFileName;

    if (updates.isNotEmpty) {
      await _client.from('relation_groups').update(updates).eq('id', groupId);
    }
  }

  Future<void> updateGroupMembers({
    required String groupId,
    required List<String> memberIds,
    required String creatorId,
  }) async {
    // 1. Get current members
    final currentMembersRaw = await _client
        .from('relation_group_members')
        .select('user_id')
        .eq('group_id', groupId);

    final currentMemberIds = (currentMembersRaw as List<dynamic>)
        .map((row) => (row as Map)['user_id'].toString())
        .toSet();

    final newMemberIds = memberIds.toSet();
    // Always keep creator
    newMemberIds.add(creatorId);

    // 2. Diff
    final toAdd = newMemberIds.difference(currentMemberIds);
    final toRemove = currentMemberIds.difference(newMemberIds);

    // 3. Apply changes
    if (toRemove.isNotEmpty) {
      // Don't remove the creator even if passed in toRemove somehow
      toRemove.remove(creatorId);
      if (toRemove.isNotEmpty) {
        await _client
            .from('relation_group_members')
            .delete()
            .eq('group_id', groupId)
            .filter(
              'user_id',
              'in',
              '(${toRemove.map((id) => '"$id"').join(',')})',
            );
      }
    }

    if (toAdd.isNotEmpty) {
      await _client
          .from('relation_group_members')
          .insert(
            toAdd
                .map(
                  (userId) => {
                    'group_id': groupId,
                    'user_id': userId,
                    'role': userId == creatorId ? 'owner' : 'member',
                  },
                )
                .toList(),
          );
    }
  }

  Future<String> _uploadGroupPhotoBytes({
    required String groupId,
    required Uint8List bytes,
  }) async {
    final storage = _client.storage.from(_storageBucket);
    final fileName = _generatePhotoFileName(groupId: groupId);
    final objectPath = _buildStoragePath(fileName);
    await storage.uploadBinary(
      objectPath,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    return fileName;
  }

  String _buildStoragePath(String fileName) => '$_storageFolder/$fileName';

  String _generatePhotoFileName({required String groupId}) {
    return '$groupId.jpg';
  }

  dynamic _normalizeRaw(dynamic raw) {
    try {
      final maybeError = raw.error;
      if (maybeError != null) throw maybeError;
      return raw.data;
    } catch (_) {
      if (raw is Map && raw.containsKey('data')) return raw['data'];
      return raw;
    }
  }
}
