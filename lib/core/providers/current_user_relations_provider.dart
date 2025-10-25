import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mydearmap/data/models/user_relation.dart';

/*final userRelationsProvider = FutureProvider.family<List<UserRelation>, String>((ref, userId) async {
  final client = Supabase.instance.client;
  final res = await client
      .from('user_relations')
      .select('*, related_user:users(*)')
      .eq('user_id', userId)
      .execute();
  if (res.error != null) throw res.error!;
  final rows = (res.data ?? []) as List<dynamic>;
  // Implementa la conversión según tu modelo UserRelation
  return rows.map((r) => UserRelation.fromMapWithRelated(r)).toList();
});*/