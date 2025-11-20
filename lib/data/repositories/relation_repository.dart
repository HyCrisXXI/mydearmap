import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final relationRepositoryProvider = Provider<RelationRepository>((ref) {
  return RelationRepository(Supabase.instance.client);
});

class RelationRepository {
  RelationRepository(this._client);

  final SupabaseClient _client;

  Future<void> createRelation({
    required String currentUserId,
    required String relatedUserIdentifier,
  }) async {
    final relatedUserId = await _resolveUserId(relatedUserIdentifier);
    await _insertRelation(currentUserId, relatedUserId);
  }

  Future<void> deleteRelation({
    required String currentUserId,
    required String relatedUserId,
  }) async {
    final raw = await _client.from('user_relations').delete().match({
      'user_id': currentUserId,
      'related_user_id': relatedUserId,
    }).select();
    final data = _normalizeRaw(raw);
    if (data == null) throw Exception('No se pudo eliminar la relación');
  }

  Future<void> updateRelationColor({
    required String currentUserId,
    required String relatedUserId,
    required String colorHex,
  }) async {
    final raw = await _client
        .from('user_relations')
        .update({'color': colorHex})
        .match({'user_id': currentUserId, 'related_user_id': relatedUserId})
        .select();
    final data = _normalizeRaw(raw);
    if (data == null) throw Exception('No se pudo actualizar el color');
  }

  Future<void> _insertRelation(String userId, String relatedUserId) async {
    final raw = await _client.from('user_relations').insert({
      'user_id': userId,
      'related_user_id': relatedUserId,
    }).select();
    final data = _normalizeRaw(raw);
    if (data == null) throw Exception('No se pudo crear la relación');
  }

  Future<String> _resolveUserId(String identifier) async {
    final iden = identifier.trim();
    if (iden.isEmpty) throw Exception('Identificador vacío');

    if (iden.contains('@')) {
      final raw = await _client
          .from('users')
          .select()
          .eq('email', iden)
          .limit(1);
      final data = _normalizeRaw(raw);
      if (data is List && data.isNotEmpty) {
        final map = Map<String, dynamic>.from(data.first as Map);
        return map['id'].toString();
      }
      throw Exception('Usuario con email $iden no encontrado');
    }

    final phonePattern = RegExp(r'^[\d+\-\s()]+$');
    if (phonePattern.hasMatch(iden)) {
      final raw = await _client
          .from('users')
          .select()
          .eq('number', iden)
          .limit(1);
      final data = _normalizeRaw(raw);
      if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first as Map)['id'].toString();
      }
    }

    final raw = await _client.from('users').select().eq('id', iden).limit(1);
    final data = _normalizeRaw(raw);
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map)['id'].toString();
    }

    throw Exception('Usuario no encontrado para identificador $iden');
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
