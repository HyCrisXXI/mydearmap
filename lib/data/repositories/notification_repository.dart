import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mydearmap/data/models/app_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> getNotificationsByUser(String userId) async {
    final rows = await _client
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows
        .whereType<Map<String, dynamic>>()
        .map<AppNotification>(AppNotification.fromMap)
        .toList(growable: false);
  }

  Stream<AppNotification> watchUserNotifications(String userId) {
    final controller = StreamController<AppNotification>.broadcast();
    final channel = _client.channel('public:notifications_user_$userId');

    void emitFromPayload(PostgresChangePayload payload) {
      controller.add(AppNotification.fromMap(payload.newRecord));
    }

    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: emitFromPayload,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: emitFromPayload,
      )
      ..subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  Future<void> markAsRead(List<String> notificationIds) async {
    if (notificationIds.isEmpty) return;
    final payload = <String, dynamic>{
      'is_read': true,
      'read': true,
      'read_at': DateTime.now().toIso8601String(),
    };
    try {
      await _client
          .from('notifications')
          .update(payload)
          .filter('id', 'in', _encodeInFilter(notificationIds));
    } catch (error, stack) {
      debugPrint('markAsRead failed: $error\n$stack');
    }
  }

  String _encodeInFilter(List<String> values) {
    final encoded = values.map((value) => '"$value"').join(',');
    return '($encoded)';
  }
}
