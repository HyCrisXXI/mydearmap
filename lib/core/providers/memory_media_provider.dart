import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mydearmap/data/models/media.dart' show mediaOrderStride;

enum MemoryMediaKind { image, video, audio, unknown }

class MemoryMedia {
  const MemoryMedia({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.order,
    this.storagePath,
    this.publicUrl,
    this.content,
    this.previewBytes,
  });

  final String id;
  final MemoryMediaKind kind;
  final DateTime createdAt;
  final int? order;
  final String? storagePath;
  final String? publicUrl;
  final String? content;
  final Uint8List? previewBytes;

  static MemoryMedia fromJson(Map<String, dynamic> json) {
    return MemoryMedia(
      id: json['id'] as String,
      kind: _parseKind(json['media_type'] as String?),
      storagePath: json['url'] as String?,
      publicUrl: _resolvePublicUrl(
        Supabase.instance.client,
        json['url'] as String?,
      ),
      content: json['content'] as String?,
      order: _parseOrder(json['order']),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

final memoryMediaProvider = FutureProvider.family
    .autoDispose<List<MemoryMedia>, String>((ref, memoryId) async {
      final client = Supabase.instance.client;

      try {
        final response = await client
            .from('media')
            .select('id, media_type, url, content, created_at, "order"')
            .eq('memory_id', memoryId)
            .order('order', ascending: true, nullsFirst: true)
            .order('created_at');

        final rows = (response as List<dynamic>)
            .map((raw) => raw as Map<String, dynamic>)
            .toList();

        final assets = rows
            .map(
              (row) => MemoryMedia(
                id: row['id'] as String,
                kind: _parseKind(row['media_type'] as String?),
                storagePath: row['url'] as String?,
                publicUrl: _resolvePublicUrl(client, row['url'] as String?),
                content: row['content'] as String?,
                order: _parseOrder(row['order']),
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

        assets.sort((a, b) {
          final orderCompare = _effectiveOrder(a).compareTo(_effectiveOrder(b));
          if (orderCompare != 0) return orderCompare;
          final priorityCompare = _priorityForKind(
            a.kind,
          ).compareTo(_priorityForKind(b.kind));
          if (priorityCompare != 0) return priorityCompare;
          return a.createdAt.compareTo(b.createdAt);
        });

        return assets;
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
    default:
      return MemoryMediaKind.unknown;
  }
}

int? _parseOrder(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

int _priorityForKind(MemoryMediaKind kind) {
  switch (kind) {
    case MemoryMediaKind.image:
      return 0;
    case MemoryMediaKind.video:
      return 1;
    case MemoryMediaKind.audio:
      return 2;
    case MemoryMediaKind.unknown:
      return 3;
  }
}

int _orderBaseForKind(MemoryMediaKind kind) =>
    mediaOrderStride * _priorityForKind(kind);

int _effectiveOrder(MemoryMedia asset) {
  final base = _orderBaseForKind(asset.kind);
  final order = asset.order;
  if (order == null) return base + mediaOrderStride - 1;
  if (order < base) {
    final relative = order >= 0 ? order : 0;
    return base + relative;
  }
  if (order >= base + mediaOrderStride) {
    final relative = (order - base) % mediaOrderStride;
    return base + relative;
  }
  return order;
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
    case MemoryMediaKind.unknown:
      return 'unknown';
  }
}
