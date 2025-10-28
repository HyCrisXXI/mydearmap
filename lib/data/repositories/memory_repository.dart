// lib/data/repositories/memory_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/memory.dart';

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

  Future<Memory?> createMemory(Memory memory) async {
    final response = await _client
        .from('memories')
        .insert(memory.toJson())
        .select()
        .single();

    return Memory.fromJson(response);
  }

  Future<Memory?> getMemoryById(String id) async {
    final response = await _client
        .from('memories')
        .select('*, participants:memory_users(*, user:users(*))')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Memory.fromJson(response);
  }

  // Esto devuelve los recuerdos del usuario solo con nombre, id y localización, para mostrarlos en el mapa
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
        .eq('id', memory.id)
        .select()
        .maybeSingle();

    if (response == null) return null;
    return Memory.fromJson(response);
  }
}
