import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/models/comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final memoryCommentsProvider = FutureProvider.family
    .autoDispose<List<Comment>, String>((ref, memoryId) async {
      final client = Supabase.instance.client;

      try {
        final response = await client
            .from('comments')
            .select(
              'id, content, subtext, created_at, updated_at, user:users(*)',
            )
            .eq('memory_id', memoryId)
            .order('created_at', ascending: false);

        final rows = (response as List)
            .whereType<Map<String, dynamic>>()
            .map(Comment.fromJson)
            .toList(growable: false);

        return rows;
      } on PostgrestException catch (error) {
        final message = error.message.toLowerCase();
        if (error.code == '42501' || message.contains('permission denied')) {
          return const <Comment>[];
        }
        throw Exception(error.message);
      } catch (error) {
        final message = error.toString().toLowerCase();
        if (message.contains('permission denied')) {
          return const <Comment>[];
        }
        throw Exception('No se pudieron cargar los comentarios ($error)');
      }
    });
