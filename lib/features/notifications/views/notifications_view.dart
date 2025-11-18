import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/notifications_provider.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/data/models/app_notification.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return currentUser.when(
      loading: () => _notificationsScaffold(
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) =>
          _notificationsScaffold(body: Center(child: Text('Error: $error'))),
      data: (user) {
        if (user == null) {
          return _notificationsScaffold(
            body: const Center(
              child: Text('Inicia sesión para ver tus notificaciones.'),
            ),
          );
        }

        final asyncNotifications = ref.watch(userNotificationsProvider);
        return asyncNotifications.when(
          loading: () =>
              _notificationsScaffold(body: const _NotificationsLoading()),
          error: (error, stack) => _notificationsScaffold(
            body: Center(child: Text('Error: $error')),
          ),
          data: (notifications) =>
              _NotificationsContent(notifications: notifications),
        );
      },
    );
  }
}

class _NotificationsContent extends ConsumerWidget {
  const _NotificationsContent({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = notifications.any((n) => !n.isRead);

    Future<void> refresh() async {
      ref.invalidate(userNotificationsProvider);
      await ref.read(userNotificationsProvider.future);
    }

    Future<void> markAllAsRead() async {
      if (!hasUnread) return;
      final ids = notifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();
      ref.read(userNotificationsCacheProvider.notifier).markManyRead(ids);
      await ref.read(notificationRepositoryProvider).markAsRead(ids);
    }

    final content = notifications.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [_NotificationsEmptyState()],
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => _markNotificationAsRead(notification, ref),
                onActionTap: notification.actionLabel == null
                    ? null
                    : () => _markNotificationAsRead(notification, ref),
              );
            },
          );

    return _notificationsScaffold(
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all),
          tooltip: 'Marcar todo como leído',
          onPressed: hasUnread ? () => markAllAsRead() : null,
        ),
      ],
      body: RefreshIndicator(onRefresh: refresh, child: content),
    );
  }
}

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const _LoadingCard(),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  height: 12,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 72,
            color: AppColors.textColor,
          ),
          const SizedBox(height: 16),
          Text('Estás al día', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Te avisaremos cuando tengas novedades de tus recuerdos y vínculos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    this.onTap,
    this.onActionTap,
  });

  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final icon = iconForKind(notification.kind);
    final badgeColor = _badgeColor(notification.kind);
    final dateLabel = DateFormat(
      'd MMM, HH:mm',
      'es_ES',
    ).format(notification.createdAt);
    final contextLine = _contextLineFrom(notification.metadata);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: unread ? AppColors.backgroundColor : AppColors.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: badgeColor.withValues(alpha: 0.18),
                  child: Icon(icon, color: badgeColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: unread
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dateLabel,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      if (notification.message != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          notification.message!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (contextLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          contextLine,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              notification.kind.name,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: badgeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          if (notification.actionLabel != null)
                            TextButton(
                              onPressed: onActionTap,
                              child: Text(notification.actionLabel!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _notificationsScaffold({required Widget body, List<Widget>? actions}) {
  return Scaffold(
    appBar: AppBar(title: const Text('Notificaciones'), actions: actions),
    body: body,
    bottomNavigationBar: const AppNavBar(currentIndex: 3),
  );
}

Color _badgeColor(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.memory:
      return AppColors.blue;
    case NotificationKind.relation:
      return AppColors.orange;
    case NotificationKind.achievement:
      return AppColors.green;
    case NotificationKind.reminder:
      return AppColors.yellow;
    case NotificationKind.invite:
      return AppColors.pink;
    case NotificationKind.system:
      return Colors.indigo;
    case NotificationKind.custom:
      return Colors.grey.shade600;
  }
}

String? _contextLineFrom(Map<String, dynamic> metadata) {
  String? pick(String key) {
    final value = metadata[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  final actor = pick('actor_name');
  final action = pick('action');
  final entity = pick('entity_name');
  final location = pick('location');

  final parts = <String>[];
  if (actor != null) parts.add(actor);
  if (action != null) parts.add(action);
  if (entity != null) parts.add(entity);

  final buffer = StringBuffer();
  if (parts.isNotEmpty) {
    buffer.write(parts.join(' · '));
  }
  if (location != null) {
    if (buffer.isNotEmpty) buffer.write(' — ');
    buffer.write(location);
  }

  final text = buffer.toString();
  return text.isEmpty ? null : text;
}

void _markNotificationAsRead(AppNotification notification, WidgetRef ref) {
  if (notification.isRead) return;
  ref.read(userNotificationsCacheProvider.notifier).markRead(notification.id);
  ref.read(notificationRepositoryProvider).markAsRead([notification.id]);
}
