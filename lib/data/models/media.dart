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
}

enum MediaType { image, video, audio, note }
