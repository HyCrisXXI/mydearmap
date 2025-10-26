import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mydearmap/data/models/user_relation.dart';


final userRelationsProvider =
    FutureProvider.family<List<UserRelation>, String>((ref, userId) async {
  final client = Supabase.instance.client;

  // Lanzamos la consulta (según versión de supabase esto puede devolver
  // PostgrestResponse, List o Map). No usamos .execute() para ser compatibles.
  final dynamic raw = await client
      .from('user_relations')
      .select('*, related_user:users(*)')
      .eq('user_id', userId);

  // Normalizamos la respuesta intentando leer .error/.data (PostgrestResponse-like)
  dynamic data;
  try {
    // si raw tiene .error/.data esto funcionará; si no, lanzará NoSuchMethodError
    final maybeError = raw.error;
    if (maybeError != null) throw maybeError;
    data = raw.data;
  } catch (_) {
    // fallback: puede ser List o Map {'data': [...] } u otra forma
    if (raw is List) {
      data = raw;
    } else if (raw is Map && raw.containsKey('data')) {
      data = raw['data'];
    } else {
      data = raw;
    }
  }

  if (data == null) return <UserRelation>[];

  final rows = (data as List<dynamic>);
  return rows
      .map((r) =>
          UserRelation.fromMapWithRelated(Map<String, dynamic>.from(r as Map)))
      .toList();
});