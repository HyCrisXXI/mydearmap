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

    if (response == null) return <MapMemory>[];

    final items = (response as List).whereType<Map<String, dynamic>>();
    return items.map((item) => MapMemory.fromJson(item)).toList();
  }

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
    return memory;
  }

  Future<List<Memory>> getMemoriesByUser(String userId) async {
    // Primero intenta la RPC (mantener compatibilidad con implementaciones que usan función en la BD)
    try {
      final response = await _client.rpc(
        'get_memories_for_user',
        params: {'user_id_param': userId},
      );

      if (response != null) {
        final items = (response as List).whereType<Map<String, dynamic>>().toList();
        if (items.isNotEmpty) {
          return items.map((item) => Memory.fromJson(item)).toList();
        }
      }
    } catch (e) {
      // no hacemos fallar la app por la RPC; seguiremos con fallback a consulta directa
      // Puedes registrar el error en logs si quieres.
      // print('RPC get_memories_for_user failed: $e');
    }

    // Fallback: obtener recuerdos mediante la tabla de unión `memory_users`
    final resp = await _client
        .from('memory_users')
        .select('memory:memories(*)')
        .eq('user_id', userId);

  final list = (resp as List)
        .map((it) => it['memory'])
        .whereType<Map<String, dynamic>>()
        .map((m) => Memory.fromJson(m))
        .toList();

    // Opcional: poblar participantes si se necesita (esto puede generar N queries)
    for (final mem in list) {
      if (mem.id != null) mem.participants = await getParticipants(mem.id!);
    }

    return list;
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
