import 'package:flutter/foundation.dart';
import 'package:mydearmap/data/models/app_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  static const List<String> _activitySources = <String>[
    'activity_log_view',
    'activity_log',
    'user_activity_log',
  ];

  Future<List<AppNotification>> getNotificationsByUser(String userId) async {
    final activities = await _fetchActivityLog(userId);
    if (activities.isNotEmpty) {
      return activities;
    }
    return _fetchLegacyNotifications(userId);
  }

  Future<void> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    final payload = <String, dynamic>{
      'is_read': true,
      'read': true,
      'read_at': DateTime.now().toIso8601String(),
    };

    for (final source in <String>[..._activitySources, 'notifications']) {
      await _markReadOn(source, payload, notificationIds);
    }
  }

  Future<void> _markReadOn(
    String table,
    Map<String, dynamic> payload,
    List<String> ids,
  ) async {
    try {
      await _client
          .from(table)
          .update(payload)
          .filter('id', 'in', _encodeInFilter(ids));
    } catch (error) {
      debugPrint('markAsRead skipped for $table: $error');
    }
  }

  Future<List<AppNotification>> _fetchActivityLog(String userId) async {
    for (final source in _activitySources) {
      try {
        final response = await _client
            .from(source)
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(100);
        final normalized = _normalizeRows(response);
        if (normalized.isEmpty) continue;
        return normalized
            .map((row) => _toNotification(row, activitySource: source))
            .toList(growable: false);
      } catch (error) {
        debugPrint('Activity source $source unavailable: $error');
      }
    }
    return const [];
  }

  Future<List<AppNotification>> _fetchLegacyNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final normalized = _normalizeRows(response);
      return normalized
          .map((row) => _toNotification(row, activitySource: 'notifications'))
          .toList(growable: false);
    } catch (error, stack) {
      debugPrint('Notifications fetch failed: $error\n$stack');
      return const [];
    }
  }

  AppNotification _toNotification(
    Map<String, dynamic> row, {
    required String activitySource,
  }) {
    final mapped = Map<String, dynamic>.from(row);
    mapped['activity_source'] = activitySource;
    mapped['title'] ??= row['summary'] ?? row['event_label'];
    mapped['message'] ??=
        row['details'] ?? row['description'] ?? row['body'] ?? row['note'];
    mapped['type'] ??= row['activity_type'] ?? row['category'];
    mapped['is_read'] ??= row['read'] ?? row['seen'];
    mapped['metadata'] = _mergeMetadata(row, activitySource);
    return AppNotification.fromMap(mapped);
  }

  Map<String, dynamic> _mergeMetadata(
    Map<String, dynamic> row,
    String activitySource,
  ) {
    final metadata = <String, dynamic>{'activity_source': activitySource};

    void addIfPresent(String key, dynamic value) {
      if (value != null) metadata[key] = value;
    }

    final rawMetadata = row['metadata'] ?? row['data'];
    if (rawMetadata is Map<String, dynamic>) {
      metadata.addAll(rawMetadata);
    } else if (rawMetadata is List) {
      metadata['items'] = rawMetadata;
    } else if (rawMetadata != null) {
      metadata['raw_metadata'] = rawMetadata;
    }

    addIfPresent('actor_name', row['actor_name'] ?? row['actor']);
    addIfPresent('actor_avatar_url', row['actor_avatar_url']);
    addIfPresent('entity_name', row['entity_name'] ?? row['target_name']);
    addIfPresent('entity_type', row['entity_type'] ?? row['target_type']);
    addIfPresent('entity_id', row['entity_id'] ?? row['target_id']);
    addIfPresent('action', row['action']);
    return metadata;
  }

  List<Map<String, dynamic>> _normalizeRows(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    if (response is Map<String, dynamic>) {
      if (response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList(growable: false);
        }
      }
      return [response];
    }
    return const [];
  }

  String _encodeInFilter(List<String> values) {
    final encoded = values.map((value) => '"$value"').join(',');
    return '($encoded)';
  }
}
