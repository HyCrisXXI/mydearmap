import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';

final relationControllerProvider =
    AsyncNotifierProvider<RelationController, void>(() {
  return RelationController();
});

class RelationController extends AsyncNotifier<void> {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<void> build() async {
    // no inicialización necesaria
  }

  /// Crea una relación: acepta identifier que puede ser email, número o id.
  Future<void> createRelation({
    required String currentUserId,
    required String relatedUserIdentifier, // email, phone o id
    required String relationType,
    
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final relatedUserId = await _resolveUserId(relatedUserIdentifier);
      
  

      await _insertRelation(currentUserId, relatedUserId, relationType);

      // invalidar cache de relaciones del usuario
      ref.invalidate(userRelationsProvider(currentUserId));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // Inserta la relación en la tabla user_relations usando los ids
  Future<void> _insertRelation(String userId, String relatedUserId, String relationType) async {
    final raw = await _client.from('user_relations').insert({
      'user_id': userId,
      'related_user_id': relatedUserId,
      'relation_type': relationType,
    }).select();

    final data = _normalizeRaw(raw);
    if (data == null) throw Exception('No se pudo crear la relación');
  }

  // Resuelve identifier -> user id. Intenta por email, luego por número, finalmente asume id directo.
  Future<String> _resolveUserId(String identifier) async {
    final iden = identifier.trim();
    if (iden.isEmpty) throw Exception('Identificador vacío');

    // 1) Email
    if (iden.contains('@')) {
      final raw = await _client.from('users').select().eq('email', iden).limit(1);
      final data = _normalizeRaw(raw);
      if (data is List && data.isNotEmpty) {
        final map = Map<String, dynamic>.from(data.first as Map);
        return map['id'].toString();
      }
      throw Exception('Usuario con email $iden no encontrado');
    }

    // 2) Número de teléfono
    final phonePattern = RegExp(r'^[\d+\-\s()]+$');
    if (phonePattern.hasMatch(iden)) {
      // Primero intenta columna 'number'
      var raw = await _client.from('users').select().eq('number', iden).limit(1);
      var data = _normalizeRaw(raw);
      if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first as Map)['id'].toString();
      }

    }

    // 3) Asumir id directo: validar existencia opcional
    final raw = await _client.from('users').select().eq('id', iden).limit(1);
    final data = _normalizeRaw(raw);
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map)['id'].toString();
    }

    throw Exception('Usuario no encontrado para identificador $iden');
  }

  // Normaliza respuesta de Supabase (PostgrestResponse vs List/Map)
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