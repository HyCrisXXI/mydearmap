import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/memory.dart';
import '../../core/utils/supabase_setup.dart';

class MemoryRepository {
  final SupabaseClient _client;

  MemoryRepository(this._client);

  /// Crear una nueva memory
  Future<Memory?> createMemory(Memory memory) async {
    final response = await _client
        .from('memories')
        .insert(memory.toMap())
        .select()
        .single();

    if (response == null) return null;
    return Memory.fromMap(response);
  }

  /// Obtener una memory por ID
  Future<Memory?> getMemoryById(String id) async {
    final response = await _client
        .from('memories')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Memory.fromMap(response);
  }

  /// Obtener todas las memories de un usuario (por ejemplo)
  Future<List<Memory>> getMemoriesByUser(String userId) async {
    final response = await _client
        .from('memories')
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((item) => Memory.fromMap(item))
        .toList();
  }

  /// Verificar si ya existe una memory con el mismo título
  Future<bool> existsByTitle(String title) async {
    final response = await _client
        .from('memories')
        .select('id', const FetchOptions(count: CountOption.exact, head: true))
        .eq('title', title);

    return (response.count ?? 0) > 0;
  }
}