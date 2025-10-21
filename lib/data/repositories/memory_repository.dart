import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/memory.dart';

class MemoryRepository {
  final SupabaseClient _client;

  MemoryRepository(this._client);

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
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Memory.fromJson(response);
  }

  Future<List<Memory>> getMemoriesByUser(String userId) async {
    final response = await _client
        .from('memories')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((item) => Memory.fromJson(item))
        .toList();
  }

  
Future<bool> existsByTitle(String title) async {
  final response = await _client
      .from('memories')
      .select('id')
      .eq('title', title);

  return response.isNotEmpty;
}

Future<bool> deleteMemory(String id) async {
  final response = await _client
        .from('memories')
        .delete().eq('id', id);

    return response.isNotEmpty;
  }
}