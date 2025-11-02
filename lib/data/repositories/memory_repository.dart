// lib/data/repositories/memory_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/memory.dart';
import '../models/user.dart';

class MemoryRepository {
  final SupabaseClient _client;

  MemoryRepository(this._client);

  Future<List<MapMemory>> getMemoriesForMap(String userId) async {
    final response = await _client.rpc(
      'get_map_memories_for_user',
      params: {'user_id_param': userId},
    );

    return (response as List).map((item) => MapMemory.fromJson(item)).toList();
  }

  Future<Memory?> createMemory(Memory memory,String userId) async {
    final response = await _client
        .from('memories')
        .insert(memory.toJson())
        .select()
        .single();
    
    Memory createdmemory = Memory.fromJson(response);
    await addParticipant(createdmemory.id!, userId , "creator");
    createdmemory.participants = await getParticipants(createdmemory.id!);
    return createdmemory;
  }

  Future<void> addParticipant(String memoryId, String userId, String role) async {
    await _client
      .from('memory_users').
        insert({
        'memory_id': memoryId,
        'user_id': userId,
        'role': role,
      });
}

Future<List<UserRole>> getParticipants(String memoryId) async {
    final response = await _client
      .from('memory_users')
      .select('*, user:users(*)')
      .eq('memory_id', memoryId);     
  
    return (response as List)
        .map((p) => UserRole(
                user: User.fromJson(p['user'] as Map<String, dynamic>),
                role: MemoryRole.values.firstWhere(
                  (r) => r.name == (p['role'] as String),
                  orElse: () => MemoryRole.guest,
                ),
              ))
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
    return memory;
  }


  Future<List<Memory>> getMemoriesByUser(String userId) async {
    final response = await _client.rpc(
      'get_memories_for_user',
      params: {'user_id_param': userId},
    );

    return (response as List).map((item) => Memory.fromJson(item)).toList();
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
