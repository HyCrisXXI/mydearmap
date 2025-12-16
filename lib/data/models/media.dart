// lib/data/models/media.dart
class Media {
  final String id;
  final MediaType type;
  final String? url;
  final String? content;
  final int? order;
  final int? durationSec;
  final DateTime createdAt;

  Media({
    required this.id,
    required this.type,
    this.url,
    this.content,
    this.order,
    this.durationSec,
    required this.createdAt,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    MediaType parseType(String type) {
      switch (type) {
        case 'image':
          return MediaType.image;
        case 'video':
          return MediaType.video;
        case 'audio':
          return MediaType.audio;
        default:
          throw Exception('Tipo de media desconocido: $type');
      }
    }

    final rawType = (json['media_type'] ?? json['type'])?.toString();
    if (rawType == null || rawType.isEmpty) {
      throw Exception('Tipo de media desconocido en la respuesta: $json');
    }
    final rawOrder = json['order'];
    final rawDuration = json['duration_sec'];

    return Media(
      id: json['id']?.toString() ?? '',
      type: parseType(rawType),
      url: json['url'] as String?,
      content: json['content'] as String?,
      order: rawOrder is int
          ? rawOrder
          : int.tryParse(rawOrder?.toString() ?? ''),
      durationSec: rawDuration is int
          ? rawDuration
          : int.tryParse(rawDuration?.toString() ?? ''),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media_type': type.name,
      'type': type.name,
      'url': url,
      'content': content,
      'order': order,
      'duration_sec': durationSec,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum MediaType { image, video, audio }

const int mediaOrderStride = 100000;

int mediaTypePriority(MediaType type) => type.index;

int mediaTypeOrderBase(MediaType type) => mediaOrderStride * type.index;

int effectiveMediaOrder(Media media) {
  final base = mediaTypeOrderBase(media.type);
  final order = media.order;
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
