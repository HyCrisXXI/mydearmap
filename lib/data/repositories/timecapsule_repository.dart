import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/timecapsule.dart';
import '../models/memory.dart';

class TimeCapsuleRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TimeCapsule>> getUserTimeCapsules(String userId) async {
    final response = await _client
        .from('time_capsules')
        .select('*, users(*)')
        .eq('creator_id', userId)
        .order('created_at', ascending: false);
    return response.map((e) => TimeCapsule.fromMap(e)).toList();
  }

  Future<TimeCapsule?> getTimeCapsuleById(String id) async {
    final response = await _client
        .from('time_capsules')
        .select('*, users(*)')
        .eq('id', id)
        .single();
    return TimeCapsule.fromMap(response);
  }

  Future<List<Memory>> getTimeCapsuleMemories(String capsuleId) async {
    final response = await _client
        .from('time_capsule_memories')
        .select('*, memories(*)')
        .eq('capsule_id', capsuleId);
    return response.map((e) => Memory.fromJson(e['memories'])).toList();
  }

  Future<List<String>> getTimeCapsuleMemoryTitles(String capsuleId) async {
    final response = await _client
        .from('time_capsule_memories')
        .select('memories(title)')
        .eq('capsule_id', capsuleId);
    return response.map((e) => e['memories']['title'] as String).toList();
  }

  Future<void> openTimeCapsule(String capsuleId) async {
    await _client
        .from('time_capsules')
        .update({'is_open': true})
        .eq('id', capsuleId);
  }

  Future<TimeCapsule> createTimeCapsule({
    required String creatorId,
    required String title,
    String? description,
    required DateTime openAt,
    required List<String> memoryIds,
  }) async {
    final response = await _client
        .from('time_capsules')
        .insert({
          'creator_id': creatorId,
          'title': title,
          'description': description,
          'open_at': openAt.toIso8601String(),
        })
        .select('*, users(*)')
        .single();
    final capsule = TimeCapsule.fromMap(response);
    await _updateCapsuleMemories(capsule.id, memoryIds);
    return capsule;
  }

  Future<TimeCapsule> updateTimeCapsule({
    required String capsuleId,
    required String title,
    String? description,
    required DateTime openAt,
    required List<String> memoryIds,
  }) async {
    final response = await _client
        .from('time_capsules')
        .update({
          'title': title,
          'description': description,
          'open_at': openAt.toIso8601String(),
        })
        .eq('id', capsuleId)
        .select('*, users(*)')
        .single();
    final capsule = TimeCapsule.fromMap(response);
    await _updateCapsuleMemories(capsuleId, memoryIds);
    return capsule;
  }

  Future<void> _updateCapsuleMemories(
    String capsuleId,
    List<String> memoryIds,
  ) async {
    // Delete existing
    await _client
        .from('time_capsule_memories')
        .delete()
        .eq('capsule_id', capsuleId);
    // Insert new
    if (memoryIds.isNotEmpty) {
      final inserts = memoryIds
          .map((id) => {'capsule_id': capsuleId, 'memory_id': id})
          .toList();
      await _client.from('time_capsule_memories').insert(inserts);
    }
  }
}
