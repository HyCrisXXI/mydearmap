// lib/data/repositories/memory_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/comment.dart';
import '../models/media.dart';
import '../models/memory.dart';
import '../models/user.dart';

class MemoryRepository {
  final SupabaseClient _client;

  MemoryRepository(this._client);

  Future<Memory?> createMemory(Memory memory, String userId) async {
    final response = await _client
        .from('memories')
        .insert(memory.toJson())
        .select()
        .single();

    Memory createdmemory = Memory.fromJson(response);
    await addParticipant(createdmemory.id!, userId, "creator");
    createdmemory.participants = await getParticipants(createdmemory.id!);
    return createdmemory;
  }

  Future<void> addParticipant(
    String memoryId,
    String userId,
    String role,
  ) async {
    await _client.from('memory_users').upsert({
      'memory_id': memoryId,
      'user_id': userId,
      'role': role,
    }, onConflict: 'memory_id,user_id');
  }

  Future<void> removeParticipant(String memoryId, String userId) async {
    await _client
        .from('memory_users')
        .delete()
        .eq('memory_id', memoryId)
        .eq('user_id', userId);
  }

  Future<List<UserRole>> getParticipants(String memoryId) async {
    final response = await _client
        .from('memory_users')
        .select('*, user:users(*)')
        .eq('memory_id', memoryId); // Todavía puedes hacer el join

    return (response as List)
        .map(
          (p) => UserRole(
            user: User.fromJson(p['user'] as Map<String, dynamic>),
            role: MemoryRole.values.firstWhere(
              (r) => r.name == (p['role'] as String),
              orElse: () => MemoryRole.guest,
            ),
          ),
        )
        .toList();
  }

  Future<Memory?> getMemoryById(String id) async {
    final response = await _client
        .from('memories')
        .select('*, participants:memory_users(*, user:users(*))')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    final memory = Memory.fromJson(response);
    memory.participants = await getParticipants(id);
    if (memory.media.isNotEmpty) {
      memory.media.sort((a, b) {
        final orderCompare = effectiveMediaOrder(
          a,
        ).compareTo(effectiveMediaOrder(b));
        if (orderCompare != 0) return orderCompare;
        final priorityCompare = mediaTypePriority(
          a.type,
        ).compareTo(mediaTypePriority(b.type));
        if (priorityCompare != 0) return priorityCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
    }
    return memory;
  }

  Future<List<Memory>> getMemoriesByUser(String userId) async {
    final response = await _client
        .from('memory_users')
        .select('''
          role,
          favorite,
          memory:memories(
            *,
            media(*),
            participants:memory_users(*, user:users(*))
          )
          ''')
        .eq('user_id', userId);
    final rows = (response as List).whereType<Map<String, dynamic>>();
    final List<Memory> memories = [];

    for (final row in rows) {
      final memoryData = row['memory'];
      if (memoryData is! Map<String, dynamic>) continue;

      final memoryJson = Map<String, dynamic>.from(memoryData);
      if (row.containsKey('favorite')) {
        memoryJson['favorite'] = row['favorite'];
      }

      final memory = Memory.fromJson(memoryJson);

      final roleValue = row['role'] as String?;
      if (roleValue != null) {
        memory.currentUserRole = MemoryRole.values.firstWhere(
          (r) => r.name == roleValue,
          orElse: () => MemoryRole.guest,
        );
      } else {
        UserRole? currentUserParticipant;
        for (final participant in memory.participants) {
          if (participant.user.id == userId) {
            currentUserParticipant = participant;
            break;
          }
        }
        if (currentUserParticipant != null) {
          memory.currentUserRole = currentUserParticipant.role;
        }
      }

      if (memory.media.isNotEmpty) {
        memory.media.sort((a, b) {
          final orderCompare = effectiveMediaOrder(
            a,
          ).compareTo(effectiveMediaOrder(b));
          if (orderCompare != 0) return orderCompare;
          final priorityCompare = mediaTypePriority(
            a.type,
          ).compareTo(mediaTypePriority(b.type));
          if (priorityCompare != 0) return priorityCompare;
          return a.createdAt.compareTo(b.createdAt);
        });
      }

      memories.add(memory);
    }

    // Filtrar recuerdos en time capsules cerradas
    final excludedIds = await _getExcludedMemoryIds();
    memories.removeWhere((memory) => excludedIds.contains(memory.id));

    memories.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return memories;
  }

  Future<List<Memory>> getMemoriesByGroup(String groupId) async {
    final response = await _client
        .from('relation_group_memories')
        .select('''
          created_at,
          memory:memories(
            *,
            media(*),
            participants:memory_users(*, user:users(*))
          )
        ''')
        .eq('group_id', groupId)
        .order('created_at', ascending: false);

    final rows = (response as List).whereType<Map<String, dynamic>>();
    final List<Memory> memories = [];

    for (final row in rows) {
      final memoryData = row['memory'];
      if (memoryData is! Map<String, dynamic>) continue;

      final memory = Memory.fromJson(Map<String, dynamic>.from(memoryData));

      if (memory.media.isNotEmpty) {
        memory.media.sort((a, b) {
          final orderCompare = effectiveMediaOrder(
            a,
          ).compareTo(effectiveMediaOrder(b));
          if (orderCompare != 0) return orderCompare;
          final priorityCompare = mediaTypePriority(
            a.type,
          ).compareTo(mediaTypePriority(b.type));
          if (priorityCompare != 0) return priorityCompare;
          return a.createdAt.compareTo(b.createdAt);
        });
      }

      memories.add(memory);
    }

    final excludedIds = await _getExcludedMemoryIds();
    memories.removeWhere((memory) => excludedIds.contains(memory.id));
    memories.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return memories;
  }

  Future<Set<String>> _getExcludedMemoryIds() async {
    final capsuleResponse = await _client
        .from('time_capsules')
        .select('id')
        .eq('is_open', false);
    final capsuleIds = (capsuleResponse as List)
        .map((e) => e['id'] as String)
        .toList();

    if (capsuleIds.isEmpty) return {};

    final response = await _client
        .from('time_capsule_memories')
        .select('memory_id')
        .filter('capsule_id', 'in', capsuleIds);
    return (response as List).map((e) => e['memory_id'] as String).toSet();
  }

  Future<bool> existsByTitle(String title) async {
    final response = await _client
        .from('memories')
        .select('id')
        .eq('title', title);

    return response.isNotEmpty;
  }

  Future<void> deleteMemory(String id) async {
    await _client.from('memories').delete().eq('id', id);
  }

  Future<Memory?> updateMemory(Memory memory) async {
    final response = await _client
        .from('memories')
        .update(memory.toJson())
        .eq('id', memory.id!)
        .select()
        .maybeSingle();

    if (response == null) return null;
    return Memory.fromJson(response);
  }

  Future<void> setFavorite({
    required String memoryId,
    required String userId,
    required bool isFavorite,
  }) async {
    await _client
        .from('memory_users')
        .update({'favorite': isFavorite})
        .eq('memory_id', memoryId)
        .eq('user_id', userId);
  }

  Future<Comment> addComment({
    required String memoryId,
    required String userId,
    required String content,
    String? subtitle,
  }) async {
    final response = await _client
        .from('comments')
        .insert({
          'memory_id': memoryId,
          'user_id': userId,
          'content': content,
          'subtext': subtitle,
        })
        .select('id, content, subtext, created_at, updated_at, user:users(*)')
        .single();

    return Comment.fromJson(response);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  Future<void> linkMemoryToGroup({
    required String groupId,
    required String memoryId,
    required String addedBy,
  }) async {
    await _client.from('relation_group_memories').upsert({
      'group_id': groupId,
      'memory_id': memoryId,
      'added_by': addedBy,
    }, onConflict: 'group_id,memory_id');
  }
}
