import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/notifications_provider.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'package:mydearmap/data/models/app_notification.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/timecapsule.dart';
import 'package:mydearmap/features/memories/controllers/memory_controller.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/timecapsules/views/timecapsule_view.dart';

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
    final visibleNotifications = notifications
        .where((notification) => !_shouldHideNotification(notification))
        .toList(growable: false);

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    final recentNotifications =
        visibleNotifications
            .where((notification) => !notification.createdAt.isBefore(cutoff))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final todayNotifications = recentNotifications
        .where((notification) => _isSameDay(notification.createdAt, now))
        .toList(growable: false);
    final lastThirtyDaysNotifications = recentNotifications
        .where((notification) => !_isSameDay(notification.createdAt, now))
        .toList(growable: false);

    final capsulesAsync = ref.watch(userTimeCapsulesProvider);

    Future<void> refresh() async {
      ref.invalidate(userNotificationsProvider);
      await ref.read(userNotificationsProvider.future);
    }

    final sectionWidgets = <Widget>[];
    if (todayNotifications.isNotEmpty) {
      sectionWidgets.addAll(
        _notificationSection(
          context: context,
          title: 'Hoy',
          items: todayNotifications,
        ),
      );
    }
    if (lastThirtyDaysNotifications.isNotEmpty) {
      sectionWidgets.addAll(
        _notificationSection(
          context: context,
          title: 'Últimos 30 días',
          items: lastThirtyDaysNotifications,
        ),
      );
    }

    final capsulesSection = capsulesAsync.when(
      data: (capsules) => _CapsulesShelf(capsules: capsules),
      loading: () => const _CapsulesLoadingPlaceholder(),
      error: (_, _) => const SizedBox.shrink(),
    );

    final listChildren = <Widget>[
      capsulesSection,
      if (sectionWidgets.isEmpty)
        const _NotificationsEmptyState()
      else
        ...sectionWidgets,
    ];

    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: listChildren,
    );

    return _notificationsScaffold(
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

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !notification.isRead;
    final icon = iconForKind(notification.kind);
    final badgeColor = Theme.of(context).colorScheme.primary;
    final relativeTime = _relativeTimeLabel(notification.createdAt);
    final memoryId = _memoryIdFromMetadata(notification.metadata);
    String? creatorName;
    if (memoryId != null) {
      final memoryAsync = ref.watch(memoryDetailProvider(memoryId));
      creatorName = memoryAsync.maybeWhen(
        data: (memory) => _creatorNameFromParticipants(memory.participants),
        orElse: () => null,
      );
    }
    final actorName =
        creatorName ??
        _actorNameFromMetadata(notification.metadata) ??
        'Alguien';
    final sharedText = '¡Te han compartido el recuerdo ${notification.title}!';
    final contextLine = _contextLineFrom(notification.metadata);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: unread ? AppColors.backgroundColor : AppColors.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _handleNotificationTap(context, ref, notification),
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
                      Text(
                        relativeTime,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              actorName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sharedText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (contextLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          contextLine,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                      ],
                      if (notification.kind != NotificationKind.custom) ...[
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
                          ],
                        ),
                      ],
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
  );
}

Future<void> _handleNotificationTap(
  BuildContext context,
  WidgetRef ref,
  AppNotification notification,
) async {
  final memoryId = _memoryIdFromMetadata(notification.metadata);
  if (memoryId == null || memoryId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta notificación no tiene un recuerdo asociado.'),
      ),
    );
    return;
  }

  final controller = ref.read(memoryControllerProvider.notifier);
  final memory = await controller.getMemoryById(memoryId);
  if (memory == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Este recuerdo ya no está disponible.')),
    );
    ref.invalidate(memoryDetailProvider(memoryId));
    return;
  }

  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => MemoryDetailView(memoryId: memoryId)),
  );
}

bool _shouldHideNotification(AppNotification notification) {
  return _metadataContainsCreatorRole(notification.metadata);
}

String _relativeTimeLabel(DateTime createdAt) {
  final now = DateTime.now();
  final diff = now.difference(createdAt);

  if (diff.inHours == 0) {
    return 'Ahora';
  }
  if (_isSameDay(createdAt, now)) {
    final hours = diff.inHours.clamp(1, 23);
    return hours == 1 ? 'Hace 1 hora' : 'Hace $hours horas';
  }
  final days = diff.inDays <= 0 ? 1 : diff.inDays;
  return days == 1 ? 'Hace 1 día' : 'Hace $days días';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _metadataContainsCreatorRole(dynamic value) {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString().toLowerCase();
      final dynamic entryValue = entry.value;
      if (key.contains('role') && entryValue is String) {
        final normalized = entryValue.trim().toLowerCase();
        if (normalized == 'creator' || normalized == 'creador') {
          return true;
        }
      }
      if (_metadataContainsCreatorRole(entryValue)) {
        return true;
      }
    }
    return false;
  }
  if (value is Iterable) {
    for (final item in value) {
      if (_metadataContainsCreatorRole(item)) return true;
    }
  }
  return false;
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

String? _memoryIdFromMetadata(dynamic metadata) {
  if (metadata is Map) {
    final direct = metadata['memory_id'] ?? metadata['memoryId'];
    if (direct != null) {
      final value = direct.toString().trim();
      if (value.isNotEmpty) return value;
    }
    for (final entry in metadata.entries) {
      final candidate = _memoryIdFromMetadata(entry.value);
      if (candidate != null) return candidate;
    }
  } else if (metadata is Iterable) {
    for (final item in metadata) {
      final candidate = _memoryIdFromMetadata(item);
      if (candidate != null) return candidate;
    }
  }
  return null;
}

String? _actorNameFromMetadata(Map<String, dynamic> metadata) {
  const keys = ['actor_name', 'actor', 'user_name', 'user', 'sender_name'];

  for (final key in keys) {
    final value = metadata[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

String? _creatorNameFromParticipants(List<UserRole> participants) {
  for (final participant in participants) {
    if (participant.role == MemoryRole.creator) {
      final name = participant.user.name.trim();
      if (name.isNotEmpty) return name;
    }
  }
  return null;
}

class _CapsulesShelf extends StatefulWidget {
  const _CapsulesShelf({required this.capsules});

  final List<TimeCapsule> capsules;

  @override
  State<_CapsulesShelf> createState() => _CapsulesShelfState();
}

class _CapsulesShelfState extends State<_CapsulesShelf> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCapsules =
        widget.capsules.where((capsule) => !capsule.isOpen).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (activeCapsules.isEmpty) {
      return const SizedBox.shrink();
    }

    final subtitle = activeCapsules.length == 1
        ? '1 cápsula activa'
        : '${activeCapsules.length} cápsulas activas';
    final previewCapsules = activeCapsules.take(3).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cápsulas de tiempo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _CapsuleCountChip(count: activeCapsules.length),
              IconButton(
                onPressed: _toggle,
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _CapsuleStackPreview(capsules: previewCapsules),
              secondChild: Column(
                children: [
                  for (var i = 0; i < activeCapsules.length; i++) ...[
                    _CapsuleExpandedTile(capsule: activeCapsules[i]),
                    if (i < activeCapsules.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapsulesLoadingPlaceholder extends StatelessWidget {
  const _CapsulesLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 160,
            height: 18,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Container(
            height: 170,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapsuleStackPreview extends StatelessWidget {
  const _CapsuleStackPreview({required this.capsules});

  final List<TimeCapsule> capsules;

  @override
  Widget build(BuildContext context) {
    if (capsules.isEmpty) {
      return const SizedBox(height: 96);
    }

    final visible = capsules.length <= 3 ? capsules : capsules.take(3).toList();
    final stackHeight = 130 + (visible.length - 1) * 12.0;

    return SizedBox(
      height: stackHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = visible.length - 1; i >= 0; i--)
            Positioned.fill(
              top: i * 12,
              child: _CapsulePreviewCard(capsule: visible[i], isTop: i == 0),
            ),
        ],
      ),
    );
  }
}

class _CapsulePreviewCard extends StatelessWidget {
  const _CapsulePreviewCard({required this.capsule, required this.isTop});

  final TimeCapsule capsule;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = isTop
        ? const LinearGradient(
            colors: [AppColors.blue, AppColors.accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [Colors.white, Colors.white70],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTop
              ? Colors.transparent
              : Colors.grey.withValues(alpha: 0.2),
        ),
        boxShadow: isTop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            capsule.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isTop ? Colors.white : AppColors.textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            capsule.description ?? 'Recuerdos esperando a abrirse.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: (isTop ? Colors.white : AppColors.textColor).withValues(
                alpha: 0.85,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.lock_clock,
                size: 16,
                color: (isTop ? Colors.white : AppColors.textColor).withValues(
                  alpha: 0.85,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _capsuleCountdownLabel(capsule),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isTop ? Colors.white : AppColors.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('d MMM', 'es_ES').format(capsule.openAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: (isTop ? Colors.white : AppColors.textColor)
                      .withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapsuleExpandedTile extends StatelessWidget {
  const _CapsuleExpandedTile({required this.capsule});

  final TimeCapsule capsule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = theme.colorScheme.primary;
    final description = capsule.description?.trim();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TimeCapsuleView(capsuleId: capsule.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: badgeColor.withValues(alpha: 0.18),
                child: Icon(Icons.lock_clock_outlined, color: badgeColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capsule.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
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
                            _capsuleCountdownLabel(capsule),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat(
                            'd MMM yyyy',
                            'es_ES',
                          ).format(capsule.openAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
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
    );
  }
}

class _CapsuleCountChip extends StatelessWidget {
  const _CapsuleCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count > 9 ? '9+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

List<Widget> _notificationSection({
  required BuildContext context,
  required String title,
  required List<AppNotification> items,
}) {
  final widgets = <Widget>[
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    const SizedBox(height: 8),
  ];

  for (var index = 0; index < items.length; index++) {
    widgets.add(_NotificationTile(notification: items[index]));
    if (index < items.length - 1) {
      widgets.add(const SizedBox(height: 6));
    }
  }

  widgets.add(const SizedBox(height: 18));
  return widgets;
}

String _capsuleCountdownLabel(TimeCapsule capsule) {
  if (capsule.isOpen || !capsule.openAt.isAfter(DateTime.now())) {
    return 'Lista para abrir';
  }

  final diff = capsule.openAt.difference(DateTime.now());
  if (diff.inDays >= 1) {
    final days = diff.inDays;
    if (days == 1) return 'Se abre mañana';
    return 'Se abre en $days días';
  }

  if (diff.inHours >= 1) {
    final hours = diff.inHours;
    if (hours == 1) return 'Se abre en 1 hora';
    return 'Se abre en $hours horas';
  }

  final minutes = diff.inMinutes.clamp(1, 59);
  return 'Se abre en $minutes min';
}
