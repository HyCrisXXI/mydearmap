import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';
import 'package:mydearmap/core/providers/notifications_provider.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:mydearmap/data/models/app_notification.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/timecapsule.dart';
import 'package:mydearmap/features/memories/controllers/memory_controller.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/timecapsules/views/timecapsule_create_view.dart';
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
      data: (capsules) => _CapsulesShelf(
        capsules: capsules,
        onCapsuleCreated: () {
          ref.invalidate(userTimeCapsulesProvider);
        },
      ),
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

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final badgeColor = theme.colorScheme.primary;
    final relativeTime = _relativeTimeLabel(notification.createdAt);
    final memoryId = _memoryIdFromMetadata(notification.metadata);

    AsyncValue<Memory>? memoryAsync;
    AsyncValue<List<MemoryMedia>>? mediaAsync;
    Memory? memory;
    List<MemoryMedia>? mediaAssets;
    String? creatorName;
    String? previewImageUrl;

    if  (memoryId != null) {
      memoryAsync = ref.watch(memoryDetailProvider(memoryId));
      mediaAsync = ref.watch(memoryMediaProvider(memoryId));
      memory = memoryAsync?.maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );
      mediaAssets = mediaAsync?.maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );

      if (memory != null) {
        creatorName = _creatorNameFromParticipants(memory.participants);
      }

      previewImageUrl = _notificationPreviewUrl(
        memory: memory,
        mediaAssets: mediaAssets,
      );
    }

    final actorName =
        creatorName ??
        _actorNameFromMetadata(notification.metadata) ??
        'Alguien';
    final sharedText = '¡Te han compartido el recuerdo ${notification.title}!';
    final contextLine = _contextLineFrom(notification.metadata);
    final hasMemoryPreview = memoryId != null;
    final isPreviewLoading =
        (memoryAsync?.isLoading ?? false) || (mediaAsync?.isLoading ?? false);
    final previewWidget = hasMemoryPreview
        ? _NotificationMemoryThumbnail(
            imageUrl: previewImageUrl,
            isLoading: isPreviewLoading,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _handleNotificationTap(context, ref, notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relativeTime,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        actorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sharedText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (contextLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          contextLine,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                      if (notification.kind != NotificationKind.custom) ...[
                        const SizedBox(height: 10),
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
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (previewWidget != null) ...[
                  const SizedBox(width: 12),
                  previewWidget,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationMemoryThumbnail extends StatelessWidget {
  const _NotificationMemoryThumbnail({
    required this.imageUrl,
    required this.isLoading,
  });

  final String? imageUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isLoading) {
      child = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      );
    } else if (imageUrl != null) {
      child = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) return widget;
          return const Center(
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) => _thumbnailPlaceholder(),
      );
    } else {
      child = _thumbnailPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 92,
        height: 92,
        color: Colors.grey.shade200,
        child: child,
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Center(
      child: Icon(
        Icons.photo_outlined,
        color: Colors.grey.shade500,
        size: 28,
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
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta notificación no tiene un recuerdo asociado.'),
        ),
      );
    }
    await _deleteNotificationById(ref, notification.id);
    return;
  }

  final controller = ref.read(memoryControllerProvider.notifier);
  final memory = await controller.getMemoryById(memoryId);
  if (memory == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este recuerdo ya no está disponible.')),
      );
    }
    ref.invalidate(memoryDetailProvider(memoryId));
    await _deleteNotificationById(ref, notification.id);
    return;
  }

  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => MemoryDetailView(memoryId: memoryId)),
  );
}

Future<void> _deleteNotificationById(
  WidgetRef ref,
  String notificationId,
) async {
  try {
    await ref
        .read(notificationRepositoryProvider)
        .deleteNotificationsByIds([notificationId]);
  } catch (_) {
    // Intentionally ignore network errors to keep UI responsive.
  }

  ref.read(userNotificationsCacheProvider.notifier).remove(notificationId);
  ref.invalidate(userNotificationsProvider);
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
  const _CapsulesShelf({required this.capsules, this.onCapsuleCreated});

  final List<TimeCapsule> capsules;
  final VoidCallback? onCapsuleCreated;

  @override
  State<_CapsulesShelf> createState() => _CapsulesShelfState();
}

class _CapsulesShelfState extends State<_CapsulesShelf> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  Future<void> _openCreateCapsule() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const TimeCapsuleCreateView(),
      ),
    );
    if (created == true) {
      widget.onCapsuleCreated?.call();
    }
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
              TextButton.icon(
                onPressed: _openCreateCapsule,
                icon: const Icon(Icons.add),
                label: const Text('Crear'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
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
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
      return const SizedBox.shrink();
    }

    final nextCapsule = capsules.reduce(
      (current, candidate) => candidate.openAt.isBefore(current.openAt)
          ? candidate
          : current,
    );

    return _CapsuleExpandedTile(
      capsule: nextCapsule,
      readOnly: true,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TimeCapsuleView(capsuleId: nextCapsule.id),
          ),
        );
      },
    );
  }
}

class _CapsuleExpandedTile extends StatelessWidget {
  const _CapsuleExpandedTile({
    required this.capsule,
    this.readOnly = false,
    this.onTap,
  });

  final TimeCapsule capsule;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = theme.colorScheme.primary;
    final description = capsule.description?.trim();

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                AppIcons.lock,
                width: 108,
                height: 108,
                fit: BoxFit.contain,
              ),
            ),
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
                    fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) * 1.5,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize:
                          (theme.textTheme.bodySmall?.fontSize ?? 14) * 1.1,
                    ),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            AppIcons.timer,
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              badgeColor,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _capsuleCountdownLabel(capsule),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
    );

    final effectiveOnTap = onTap ?? () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TimeCapsuleView(capsuleId: capsule.id),
        ),
      );
    };

    final child = readOnly
      ? GestureDetector(onTap: onTap, child: content)
      : InkWell(
        borderRadius: BorderRadius.circular(20),
            onTap: effectiveOnTap,
        child: content,
        );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: child,
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

String? _notificationPreviewUrl({
  Memory? memory,
  List<MemoryMedia>? mediaAssets,
}) {
  final memoryUrl = memory != null ? _memoryPreviewImageUrl(memory) : null;
  if (memoryUrl != null) return memoryUrl;

  if (mediaAssets == null || mediaAssets.isEmpty) return null;

  for (final asset in mediaAssets) {
    final url = asset.publicUrl;
    if (asset.kind == MemoryMediaKind.image && url != null && url.isNotEmpty) {
      return url;
    }
  }

  for (final asset in mediaAssets) {
    final url = asset.publicUrl;
    if (url != null && url.isNotEmpty) {
      return url;
    }
  }

  return null;
}

String? _memoryPreviewImageUrl(Memory memory) {
  Media? primaryImage;
  for (final media in memory.media) {
    final url = media.url;
    if (url == null || url.isEmpty) continue;
    if (media.type == MediaType.image) {
      primaryImage = media;
      break;
    }
  }

  if (primaryImage != null) {
    return buildMediaPublicUrl(primaryImage.url);
  }

  for (final media in memory.media) {
    final url = media.url;
    if (url != null && url.isNotEmpty) {
      return buildMediaPublicUrl(url);
    }
  }

  return null;
}

String _capsuleCountdownLabel(TimeCapsule capsule) {
  if (capsule.isOpen || !capsule.openAt.isAfter(DateTime.now())) {
    return 'Lista para abrir';
  }

  final diff = capsule.openAt.difference(DateTime.now());
  if (diff.inDays >= 1) {
    final days = diff.inDays;
    if (days == 1) return 'Mañana';
    return '$days días';
  }

  if (diff.inHours >= 1) {
    final hours = diff.inHours;
    if (hours == 1) return '1 hora';
    return '$hours horas';
  }

  final minutes = diff.inMinutes.clamp(1, 59);
  return '$minutes min';
}
