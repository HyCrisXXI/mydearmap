class Media {
  final int id;
  final MediaType type;
  final String? url;
  final String? content;
  final int? durationSec;
  final DateTime createdAt;

  Media({
    required this.id,
    required this.type,
    this.url,
    this.content,
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
        case 'note':
          return MediaType.note;
        default:
          throw Exception('Tipo de media desconocido: $type');
      }
    }

    return Media(
      id: json['id'] as int,
      type: parseType(json['type'] as String),
      url: json['url'] as String?,
      content: json['content'] as String?,
      durationSec: json['durationSec'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'url' : url,
      'content': content,
      'durationSec': durationSec,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum MediaType { image, video, audio, note }
