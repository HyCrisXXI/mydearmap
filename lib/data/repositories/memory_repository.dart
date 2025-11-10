// lib/data/repositories/memory_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
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
    await _client.from('memory_users').insert({
      'memory_id': memoryId,
      'user_id': userId,
      'role': role,
    });
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

      final memory = Memory.fromJson(memoryData);

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

    memories.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    return memories;
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
}
