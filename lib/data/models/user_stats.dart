// lib/data/models/user_stats.dart
class UserStats {
  final int memoriesUploaded;
  final int commentsPosted;
  final int reactionsGiven;
  final DateTime lastUpdated;

  UserStats({
    required this.memoriesUploaded,
    required this.commentsPosted,
    required this.reactionsGiven,
    required this.lastUpdated,
  });
}
