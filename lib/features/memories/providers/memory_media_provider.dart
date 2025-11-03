import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MemoryMediaKind { image, video, audio, note, unknown }

class MemoryMedia {
  const MemoryMedia({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.storagePath,
    this.publicUrl,
    this.content,
  });

  final String id;
  final MemoryMediaKind kind;
  final DateTime createdAt;
  final String? storagePath;
  final String? publicUrl;
  final String? content;
}

final memoryMediaProvider = FutureProvider.family
    .autoDispose<List<MemoryMedia>, String>((ref, memoryId) async {
      final client = Supabase.instance.client;

      try {
        final response = await client
            .from('media')
            .select('id, media_type, url, content, created_at')
            .eq('memory_id', memoryId)
            .order('created_at');

        final rows = (response as List<dynamic>)
            .map((raw) => raw as Map<String, dynamic>)
            .toList();

        return rows
            .map(
              (row) => MemoryMedia(
                id: row['id'] as String,
                kind: _parseKind(row['media_type'] as String?),
                storagePath: row['url'] as String?,
                publicUrl: _resolvePublicUrl(client, row['url'] as String?),
                content: row['content'] as String?,
                createdAt:
                    DateTime.tryParse(row['created_at'] as String? ?? '') ??
                    DateTime.now(),
              ),
            )
            .where(
              (asset) =>
                  asset.publicUrl != null ||
                  asset.content?.trim().isNotEmpty == true,
            )
            .toList();
      } on PostgrestException catch (error) {
        final message = error.message.toLowerCase();
        if (error.code == '42501' || message.contains('permission denied')) {
          return const [];
        }
        throw Exception(error.message);
      } catch (error) {
        final message = error.toString().toLowerCase();
        if (message.contains('permission denied')) {
          return const [];
        }
        throw Exception('Error al obtener los archivos adjuntos ($error)');
      }
    });

MemoryMediaKind _parseKind(String? value) {
  switch (value) {
    case 'image':
      return MemoryMediaKind.image;
    case 'video':
      return MemoryMediaKind.video;
    case 'audio':
      return MemoryMediaKind.audio;
    case 'note':
      return MemoryMediaKind.note;
    default:
      return MemoryMediaKind.unknown;
  }
}

String? _resolvePublicUrl(SupabaseClient client, String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return client.storage.from('media').getPublicUrl(path);
}

String kindToStorageSegment(MemoryMediaKind kind) {
  switch (kind) {
    case MemoryMediaKind.image:
      return 'images';
    case MemoryMediaKind.video:
      return 'videos';
    case MemoryMediaKind.audio:
      return 'audios';
    case MemoryMediaKind.note:
      return 'notes';
    case MemoryMediaKind.unknown:
      return 'others';
  }
}

String kindToDatabaseValue(MemoryMediaKind kind) {
  switch (kind) {
    case MemoryMediaKind.image:
      return 'image';
    case MemoryMediaKind.video:
      return 'video';
    case MemoryMediaKind.audio:
      return 'audio';
    case MemoryMediaKind.note:
      return 'note';
    case MemoryMediaKind.unknown:
      return 'unknown';
  }
}
