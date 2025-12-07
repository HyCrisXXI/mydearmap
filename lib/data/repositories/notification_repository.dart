import 'dart:async';

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

  Future<void> deleteNotificationsOlderThan(
    String userId,
    DateTime cutoff,
  ) async {
    await _client
        .from('notifications')
        .delete()
        .eq('user_id', userId)
        .lt('created_at', cutoff.toIso8601String());
  }

  Future<void> deleteNotificationsByIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final formatted = ids.map((id) => '"$id"').join(',');
    await _client
        .from('notifications')
        .delete()
        .filter('id', 'in', '($formatted)');
  }

}
