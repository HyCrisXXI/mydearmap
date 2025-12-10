import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/models/relation_group.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';

final relationGroupRepositoryProvider = Provider<RelationGroupRepository>((
  ref,
) {
  return RelationGroupRepository(Supabase.instance.client);
});

class RelationGroupRepository {
  RelationGroupRepository(this._client);

  final SupabaseClient _client;
  static const _storageBucket = 'media';

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
    String? photoUrl;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      final storage = _client.storage.from(_storageBucket);
      final objectPath = _buildStoragePath(
        creatorId: creatorId,
        originalFilename: photoFilename,
      );
      await storage.uploadBinary(
        objectPath,
        photoBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _inferMimeType(photoFilename),
        ),
      );
      photoUrl = storage.getPublicUrl(objectPath);
    }

    final inserted = await _client
        .from('relation_groups')
        .insert({'name': name, 'photo_url': photoUrl, 'creator_id': creatorId})
        .select()
        .single();

    final groupId = inserted['id'].toString();
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

  String _buildStoragePath({
    required String creatorId,
    String? originalFilename,
  }) {
    final extension =
        (originalFilename != null && originalFilename.contains('.'))
        ? originalFilename.split('.').last
        : 'jpg';
    final sanitizedExt = extension.toLowerCase();
    return 'groupps/$creatorId/${const Uuid().v4()}.$sanitizedExt';
  }

  String _inferMimeType(String? filename) {
    final lower = filename?.toLowerCase() ?? '';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
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
