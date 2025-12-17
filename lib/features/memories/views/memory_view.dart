// lib/features/memories/views/memory_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/providers/memory_comments_provider.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';
import 'package:mydearmap/core/providers/geocoding_provider.dart';
import 'package:mydearmap/data/models/comment.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/features/memories/controllers/memory_controller.dart';
import 'package:mydearmap/features/memories/views/memory_form_view.dart';
import 'package:mydearmap/features/memories/widgets/memory_comment_card.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/core/widgets/pulse_button.dart';

final memoryDetailProvider = FutureProvider.family<Memory, String>((
  ref,
  memoryId,
) async {
  final controller = ref.read(memoryControllerProvider.notifier);
  final memory = await controller.getMemoryById(memoryId);
  if (memory == null) {
    throw Exception('Recuerdo no disponible');
  }
  return memory;
});

class MemoryDetailView extends ConsumerWidget {
  const MemoryDetailView({required this.memoryId, super.key});

  final String memoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(memoryDetailProvider(memoryId));
    final mapMemoriesAsync = ref.watch(userMemoriesProvider);
    final commentsAsync = ref.watch(memoryCommentsProvider(memoryId));
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: null,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.paddingLarge,
                  AppSizes.upperPadding,
                  AppSizes.paddingLarge,
                  AppSizes.paddingMedium,
                ),
                child: Row(
                  children: [
                    PulseButton(
                      child: IconButton(
                        icon: SvgPicture.asset(AppIcons.chevronLeft),
                        onPressed: () => Navigator.of(context).pop(),
                        style: AppButtonStyles.circularIconButton,
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSmallMedium),
                    Expanded(
                      child: memoryAsync.maybeWhen(
                        data: (memory) => Text(
                          memory.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        orElse: () => const Text('Detalle del recuerdo'),
                      ),
                    ),
                    PulseButton(
                      child: IconButton(
                        icon: SvgPicture.asset(AppIcons.pencil),
                        style: AppButtonStyles.circularIconButton,
                        tooltip: 'Editar recuerdo',
                        onPressed: () async {
                          final refreshed = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MemoryDetailEditView(memoryId: memoryId),
                                ),
                              );
                          if (!context.mounted) return;
                          if (refreshed == true) {
                            ref.invalidate(memoryDetailProvider(memoryId));
                            ref.invalidate(memoryMediaProvider(memoryId));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: memoryAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (error, _) => Center(
                    child: Text('No se pudo cargar el recuerdo: $error'),
                  ),
                  data: (memory) {
                    final happenedAt = memory.happenedAt;
                    final latLng = _resolveMemoryLocation(
                      memory,
                      mapMemoriesAsync,
                    );
                    final description = _readDescription(memory);
                    final mediaAsync = ref.watch(memoryMediaProvider(memoryId));
                    final currentUser = currentUserAsync.maybeWhen(
                      data: (user) => user,
                      orElse: () => null,
                    );
                    final AsyncValue<String>? locationLabelAsync =
                        latLng != null
                        ? ref.watch(reverseGeocodeProvider(latLng))
                        : null;
                    final locationTextStyle = Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.accentColor);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: AppSizes.modalMaxWidth,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SvgPicture.asset(
                                              AppIcons.calendar,
                                              width: 18,
                                              height: 18,
                                              colorFilter: ColorFilter.mode(
                                                Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color ??
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatDate(happenedAt),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        if (latLng != null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.place,
                                                size: 16,
                                                color: AppColors.accentColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child:
                                                    locationLabelAsync?.maybeWhen(
                                                      data: (value) => Text(
                                                        value,
                                                        style:
                                                            locationTextStyle,
                                                      ),
                                                      orElse: () => Text(
                                                        _formatLocationLabel(
                                                          latLng,
                                                        ),
                                                        style:
                                                            locationTextStyle,
                                                      ),
                                                    ) ??
                                                    Text(
                                                      _formatLocationLabel(
                                                        latLng,
                                                      ),
                                                      style: locationTextStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: memory.participants.isNotEmpty
                                          ? _ParticipantsHeaderPreview(
                                              participants: memory.participants,
                                              onTap: () =>
                                                  _showParticipantsSheet(
                                                    context,
                                                    memory.participants,
                                                  ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.paddingLarge),
                            Center(
                              child: Text(
                                description,
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(height: 1.0),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSizes.paddingLarge),
                          _buildMixedTimeline(
                            context: context,
                            mediaAsync: mediaAsync,
                            commentsAsync: commentsAsync,
                            memory: memory,
                            ref: ref,
                            currentUser: currentUser,
                          ),
                          const SizedBox(height: AppSizes.paddingMedium),
                          _CommentInputWidget(memoryId: memoryId),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantsHeaderPreview extends StatelessWidget {
  const _ParticipantsHeaderPreview({required this.participants, this.onTap});

  final List<UserRole> participants;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final preview = participants.take(2).toList(growable: false);
    if (preview.isEmpty) return const SizedBox.shrink();

    const avatarSize = 48.0;
    const overlap = 20.0;
    final stackWidth = avatarSize + (preview.length - 1) * overlap;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(-8, 0),
            child: SizedBox(
              width: stackWidth,
              height: avatarSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (preview.length > 1)
                    Positioned(
                      left: overlap,
                      child: _ParticipantAvatar(
                        user: preview[1].user,
                        size: avatarSize,
                      ),
                    ),
                  Positioned(
                    left: 0,
                    child: _ParticipantAvatar(
                      user: preview[0].user,
                      size: avatarSize,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppIcons.usersRound,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  AppColors.accentColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                participants.length.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({required this.user, this.size = 40});

  final User user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _resolveAvatarUrl(user.profileUrl);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        color: Colors.grey.shade200,
        image: avatarUrl != null
            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
            : null,
      ),
      child: avatarUrl == null
          ? Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}

enum _TimelineEntryKind { media, comment }

class _TimelineEntry {
  _TimelineEntry.media(this.media)
    : comment = null,
      kind = _TimelineEntryKind.media,
      createdAt = media?.createdAt ?? DateTime.now();

  _TimelineEntry.comment(this.comment)
    : media = null,
      kind = _TimelineEntryKind.comment,
      createdAt = comment?.createdAt ?? DateTime.now();

  final MemoryMedia? media;
  final Comment? comment;
  final _TimelineEntryKind kind;
  final DateTime createdAt;
}

Widget _buildMixedTimeline({
  required BuildContext context,
  required AsyncValue<List<MemoryMedia>> mediaAsync,
  required AsyncValue<List<Comment>> commentsAsync,
  required Memory memory,
  required WidgetRef ref,
  required User? currentUser,
}) {
  return mediaAsync.when(
    loading: () => const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.paddingLarge),
      child: Center(child: CircularProgressIndicator.adaptive()),
    ),
    error: (error, _) => Text('No se pudo cargar la galería: $error'),
    data: (media) {
      final galleryMedia = media;
      return commentsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.paddingLarge),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (error, _) =>
            Text('No se pudieron cargar los comentarios: $error'),
        data: (comments) {
          final entries = <_TimelineEntry>[
            ...galleryMedia.map(_TimelineEntry.media),
            ...comments.map(_TimelineEntry.comment),
          ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          if (entries.isEmpty) {
            return const Text('Todavía no hay recuerdos compartidos.');
          }
          return Column(
            children: entries.asMap().entries.map((mapEntry) {
              final entry = mapEntry.value;

              if (entry.kind == _TimelineEntryKind.media) {
                // Calculate the index of this media within the galleryMedia list
                final mediaIndex = galleryMedia.indexOf(entry.media!);
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSizes.paddingMedium,
                  ),
                  child: _VerticalMediaAttachment(
                    asset: entry.media!,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      _showFullScreenGallery(context, galleryMedia, mediaIndex);
                    },
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
                child: MemoryCommentCard(
                  comment: entry.comment!,
                  onDelete:
                      currentUser != null &&
                          memory.id != null &&
                          entry.comment!.user.id == currentUser.id
                      ? () => _confirmDeleteComment(
                          context,
                          ref,
                          memory.id!,
                          entry.comment!.id,
                        )
                      : null,
                ),
              );
            }).toList(),
          );
        },
      );
    },
  );
}

class _VerticalMediaAttachment extends StatelessWidget {
  const _VerticalMediaAttachment({
    required this.asset,
    this.onTap,
    this.isFullScreen = false,
  });

  final MemoryMedia asset;
  final VoidCallback? onTap;
  final bool isFullScreen;

  @override
  Widget build(BuildContext context) {
    switch (asset.kind) {
      case MemoryMediaKind.image:
        return _buildImage(context);
      case MemoryMediaKind.video:
        return _buildActionCard(
          context,
          icon: Icons.play_circle_outline,
          color: Colors.deepPurple,
          title: 'Video adjunto',
          description: 'Copia el enlace para reproducirlo.',
        );
      case MemoryMediaKind.audio:
        return _buildActionCard(
          context,
          icon: Icons.graphic_eq,
          color: Colors.teal,
          title: 'Audio adjunto',
          description: 'Copia el enlace para escucharlo.',
        );
      case MemoryMediaKind.unknown:
        return const _InlineMediaNotice(
          message: 'Este tipo de archivo no se puede mostrar.',
        );
    }
  }

  Widget _buildImage(BuildContext context) {
    final url = asset.publicUrl;
    if (url == null || url.isEmpty) {
      return const _InlineMediaNotice(
        message: 'Imagen sin ruta pública disponible.',
      );
    }

    if (isFullScreen) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator.adaptive());
        },
        errorBuilder: (_, _, _) => const Center(child: Icon(Icons.error)),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _copyMediaLink(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Image.network(
          url,
          fit: BoxFit.fitWidth,
          width: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.paddingLarge),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          },
          errorBuilder: (context, error, stackTrace) => const Padding(
            padding: EdgeInsets.all(AppSizes.paddingLarge),
            child: Text(
              'Error cargando la imagen',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color.withAlpha(230)),
          ),
          if (asset.publicUrl != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _copyMediaLink(context, asset.publicUrl!),
              icon: const Icon(Icons.link),
              label: const Text('Copiar enlace'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineMediaNotice extends StatelessWidget {
  const _InlineMediaNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      width: double.infinity,
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

Future<void> _showFullScreenGallery(
  BuildContext context,
  List<MemoryMedia> galleryMedia,
  int initialIndex,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FullScreenMediaGallery(
        media: galleryMedia,
        initialIndex: initialIndex,
      ),
      fullscreenDialog: true,
    ),
  );
}

class FullScreenMediaGallery extends StatefulWidget {
  const FullScreenMediaGallery({
    required this.media,
    required this.initialIndex,
    super.key,
  });

  final List<MemoryMedia> media;
  final int initialIndex;

  @override
  State<FullScreenMediaGallery> createState() => _FullScreenMediaGalleryState();
}

class _FullScreenMediaGalleryState extends State<FullScreenMediaGallery> {
  late PageController _pageController;
  late int _currentIndex;
  ScrollPhysics _physics = const BouncingScrollPhysics();
  bool _isLocked = false;
  int _activePointers = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _updatePhysics() {
    final shouldLock = _isLocked || _activePointers >= 2;
    final newPhysics = shouldLock
        ? const NeverScrollableScrollPhysics()
        : const BouncingScrollPhysics();
    if (newPhysics.runtimeType != _physics.runtimeType) {
      setState(() => _physics = newPhysics);
    }
  }

  void _handleZoomChanged(bool isZoomed) {
    if (isZoomed != _isLocked) {
      _isLocked = isZoomed;
      _updatePhysics();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDateForGallery(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentMedia = widget.media[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(AppIcons.initWorldBG, fit: BoxFit.cover),
          ),
          // Gallery PageView
          Positioned.fill(
            child: Listener(
              onPointerDown: (_) {
                _activePointers++;
                _updatePhysics();
              },
              onPointerUp: (_) {
                _activePointers--;
                if (_activePointers < 0) _activePointers = 0;
                _updatePhysics();
              },
              onPointerCancel: (_) {
                _activePointers--;
                if (_activePointers < 0) _activePointers = 0;
                _updatePhysics();
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.media.length,
                physics: _physics,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.media[index];
                  if (item.kind == MemoryMediaKind.video) {
                    return Center(
                      child: _VerticalMediaAttachment(
                        asset: item,
                        isFullScreen: true,
                      ),
                    );
                  }

                  final url = item.publicUrl;
                  if (url == null) return const SizedBox.shrink();

                  return _ZoomableImage(
                    url: url,
                    onZoomChanged: _handleZoomChanged,
                  );
                },
              ),
            ),
          ),

          // Custom Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingLarge,
                AppSizes.upperPadding, // Use standard upper padding
                AppSizes.paddingLarge,
                AppSizes.paddingMedium,
              ),
              color: AppColors.primaryColor.withValues(alpha: 0.0),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: SvgPicture.asset(AppIcons.chevronLeft),
                      onPressed: () => Navigator.of(context).pop(),
                      style: AppButtonStyles.circularIconButton,
                    ),
                    const SizedBox(width: AppSizes.paddingSmallMedium),
                    Text(
                      _formatDateForGallery(currentMedia.createdAt),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _copyMediaLink(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Enlace copiado al portapapeles')),
  );
}

String _readDescription(Memory memory) => memory.description?.trim() ?? '';

Future<void> _showParticipantsSheet(
  BuildContext context,
  List<UserRole> participants,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      final user = participant.user;
                      return ListTile(
                        leading: _ParticipantAvatar(user: user, size: 48),
                        title: Text(user.name),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String? _resolveAvatarUrl(String? raw) => buildAvatarUrl(raw);

LatLng? _resolveMemoryLocation(
  Memory memory,
  AsyncValue<List<Memory>> mapMemories,
) {
  final direct = memory.location;
  if (direct != null) {
    return LatLng(direct.latitude, direct.longitude);
  }

  return mapMemories.when(
    data: (memories) {
      for (final candidate in memories) {
        if (candidate.id == memory.id && candidate.location != null) {
          final geo = candidate.location!;
          return LatLng(geo.latitude, geo.longitude);
        }
      }
      return null;
    },
    loading: () => null,
    error: (_, _) => null,
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatLocationLabel(LatLng point) {
  final lat = point.latitude.toStringAsFixed(4);
  final lng = point.longitude.toStringAsFixed(4);
  return 'Lat $lat, Lon $lng';
}

Future<void> _confirmDeleteComment(
  BuildContext context,
  WidgetRef ref,
  String memoryId,
  String commentId,
) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Eliminar comentario'),
      content: const Text(
        'Esta acción no se puede deshacer. ¿Deseas continuar?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (!context.mounted) return;
            Navigator.of(dialogContext).pop(false);
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!context.mounted) return;
            Navigator.of(dialogContext).pop(true);
          },
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (shouldDelete == true) {
    try {
      final repository = ref.read(memoryRepositoryProvider);
      await repository.deleteComment(commentId);
      ref.invalidate(memoryCommentsProvider(memoryId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comentario eliminado')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
    }
  }
}

class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.url, required this.onZoomChanged});

  final String url;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChange);
  }

  void _onTransformationChange() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    widget.onZoomChanged(scale > 1.05);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator.adaptive());
          },
        ),
      ),
    );
  }
}

class _CommentInputWidget extends ConsumerStatefulWidget {
  const _CommentInputWidget({required this.memoryId});

  final String memoryId;

  @override
  ConsumerState<_CommentInputWidget> createState() =>
      _CommentInputWidgetState();
}

class _CommentInputWidgetState extends ConsumerState<_CommentInputWidget> {
  late final TextEditingController _contentController;
  late final TextEditingController _subtitleController;
  // ignore: unused_field
  final _formKey = GlobalKey<FormState>(); // Kept for structure if needed
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _subtitleController = TextEditingController();
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para comentar.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final repository = ref.read(memoryRepositoryProvider);
      final subtitle = _subtitleController.text.trim();

      await repository.addComment(
        memoryId: widget.memoryId,
        userId: user.id,
        content: content,
        subtitle: subtitle.isNotEmpty ? subtitle : null,
      );

      ref.invalidate(memoryCommentsProvider(widget.memoryId));
      _contentController.clear();
      _subtitleController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comentario publicado')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo publicar: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formattedDate() {
    try {
      return DateFormat('dd/MM/yyyy', 'es_ES').format(DateTime.now());
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserAsync = ref.watch(currentUserProvider);
    final user = currentUserAsync.asData?.value;

    if (user == null) return const SizedBox.shrink();

    final canSend = !_isSubmitting && _contentController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            offset: const Offset(0, 8),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ParticipantAvatar(
                user: user,
                size: 48,
              ), // Reusing existing avatar widget
              const SizedBox(width: AppSizes.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          AppIcons.calendar,
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Color.fromARGB(255, 94, 103, 242),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formattedDate(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Send Button
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: canSend ? _handleSubmit : null,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        )
                      : Center(
                          child: SvgPicture.asset(
                            AppIcons.send,
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              canSend ? AppColors.blue : AppColors.textColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          // Content Input
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: 'Describe el momento',
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            minLines: 1,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Divider(
            color: theme.colorScheme.outlineVariant.withAlpha(0x66),
            thickness: 0.5,
            height: 12,
          ),
          // Subtitle Input
          TextField(
            controller: _subtitleController,
            decoration: const InputDecoration(
              hintText: 'Subtexto (opcional)',
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isCollapsed: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: (theme.textTheme.bodySmall?.fontSize ?? 14) + 1,
            ),
            minLines: 1,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
