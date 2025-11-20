import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/data/models/app_notification.dart';
import 'package:mydearmap/data/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(Supabase.instance.client);
});

final userNotificationsCacheProvider =
    NotifierProvider<UserNotificationsCacheNotifier, List<AppNotification>>(
      UserNotificationsCacheNotifier.new,
    );

final userNotificationsRealtimeProvider =
    StreamProvider.family<AppNotification, String>((ref, userId) {
  return ref.watch(notificationRepositoryProvider)
      .watchUserNotifications(userId);
});

class UserNotificationsCacheNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() {
    ref.listen(currentUserProvider, (previous, next) {
      final prevId = previous?.asData?.value?.id;
      final nextId = next.asData?.value?.id;
      if (prevId != nextId) {
        reset();
      }
    });
    return const <AppNotification>[];
  }

  void reset() => state = const <AppNotification>[];

  void setAll(List<AppNotification> items) {
    final sorted = List<AppNotification>.of(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = List<AppNotification>.unmodifiable(sorted);
  }

  void markRead(String notificationId) {
    state = [
      for (final notification in state)
        if (notification.id == notificationId)
          notification.copyWith(
            isRead: true,
            readAt: notification.readAt ?? DateTime.now(),
          )
        else
          notification,
    ];
  }

  void markManyRead(Iterable<String> notificationIds) {
    final ids = notificationIds.toSet();
    if (ids.isEmpty) return;
    state = [
      for (final notification in state)
        if (ids.contains(notification.id))
          notification.copyWith(
            isRead: true,
            readAt: notification.readAt ?? DateTime.now(),
          )
        else
          notification,
    ];
  }

  void upsert(AppNotification notification) {
    final next = <AppNotification>[notification,
      ...state.where((item) => item.id != notification.id),
    ]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = List<AppNotification>.unmodifiable(next);
  }
}

final userNotificationsProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final userValue = ref.watch(currentUserProvider);
  final cacheNotifier = ref.read(userNotificationsCacheProvider.notifier);
  final cached = ref.read(userNotificationsCacheProvider);

  if (userValue.isLoading) {
    return cached;
  }

  if (userValue.hasError) {
    cacheNotifier.reset();
    throw userValue.error ?? Exception('No se pudo obtener el usuario actual');
  }

  final user = userValue.value;
  if (user == null) {
    cacheNotifier.reset();
    return const <AppNotification>[];
  }

  ref.listen<AsyncValue<AppNotification>>(
    userNotificationsRealtimeProvider(user.id),
    (previous, next) {
      next.whenData(cacheNotifier.upsert);
    },
  );

  if (cached.isNotEmpty) return cached;

  final repo = ref.read(notificationRepositoryProvider);
  final fetched = await repo.getNotificationsByUser(user.id);
  cacheNotifier.setAll(fetched);
  return fetched;
});
