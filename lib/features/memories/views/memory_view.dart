// lib/features/memories/views/memory_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: SafeArea(
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
                  IconButton(
                    icon: SvgPicture.asset(AppIcons.chevronLeft),
                    onPressed: () => Navigator.of(context).pop(),
                    style: AppButtonStyles.circularIconButton,
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
                      ),
                      orElse: () => const Text('Detalle del recuerdo'),
                    ),
                  ),
                  PopupMenuButton<_MemoryDetailMenuAction>(
                    icon: SvgPicture.asset(AppIcons.ellipsisVertical),
                    style: AppButtonStyles.circularIconButton,
                    tooltip: 'Más opciones',
                    onSelected: (action) async {
                      switch (action) {
                        case _MemoryDetailMenuAction.editMemory:
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
                          break;
                        case _MemoryDetailMenuAction.createComment:
                          if (!context.mounted) return;
                          await _showCommentComposer(context, ref, memoryId);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _MemoryDetailMenuAction.editMemory,
                        child: Text('Editar recuerdo'),
                      ),
                      PopupMenuItem(
                        value: _MemoryDetailMenuAction.createComment,
                        child: Text('Crear comentario'),
                      ),
                    ],
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
                  final AsyncValue<String>? locationLabelAsync = latLng != null
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
                                                      style: locationTextStyle,
                                                    ),
                                                    orElse: () => Text(
                                                      _formatLocationLabel(
                                                        latLng,
                                                      ),
                                                      style: locationTextStyle,
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
                                            onTap: () => _showParticipantsSheet(
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
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MemoryDetailMenuAction { editMemory, createComment }

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
      final galleryMedia = media
          .where((asset) => asset.kind != MemoryMediaKind.note)
          .toList();
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
            children: entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSizes.paddingMedium,
                    ),
                    child: entry.kind == _TimelineEntryKind.media
                        ? _VerticalMediaAttachment(asset: entry.media!)
                        : MemoryCommentCard(
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
                  ),
                )
                .toList(),
          );
        },
      );
    },
  );
}

class _VerticalMediaAttachment extends StatelessWidget {
  const _VerticalMediaAttachment({required this.asset});

  final MemoryMedia asset;

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
      case MemoryMediaKind.note:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImage(BuildContext context) {
    final url = asset.publicUrl;
    if (url == null || url.isEmpty) {
      return const _InlineMediaNotice(
        message: 'Imagen sin ruta pública disponible.',
      );
    }
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, url),
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

Future<void> _copyMediaLink(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Enlace copiado al portapapeles')),
  );
}

Future<void> _showFullScreenImage(BuildContext context, String url) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
    ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLarge,
                    vertical: AppSizes.paddingSmall,
                  ),
                  child: Text(
                    'Participantes',
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: participants.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
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

String? _resolveAvatarUrl(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  return 'https://oomglkpxogeiwrrfphon.supabase.co/storage/v1/object/public/media/avatars/$raw';
}

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

class _CommentComposerDialog extends ConsumerStatefulWidget {
  const _CommentComposerDialog({required this.memoryId});

  final String memoryId;

  @override
  ConsumerState<_CommentComposerDialog> createState() =>
      _CommentComposerDialogState();
}

class _CommentComposerDialogState
    extends ConsumerState<_CommentComposerDialog> {
  late final TextEditingController _contentController;
  late final TextEditingController _subtitleController;
  final _formKey = GlobalKey<FormState>();
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _subtitleController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: viewInsets),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nuevo comentario',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (!context.mounted) return;
                                Navigator.of(context).pop(false);
                              },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Describe el momento',
                    ),
                    minLines: 1,
                    maxLines: 6,
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Escribe un título';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  TextFormField(
                    controller: _subtitleController,
                    decoration: const InputDecoration(
                      labelText: 'Subtexto (opcional)',
                      hintText: 'Describe el momento',
                    ),
                    minLines: 1,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (!context.mounted) return;
                                Navigator.of(context).pop(false);
                              },
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                setState(() => _isSubmitting = true);
                                try {
                                  final user = await ref.read(
                                    currentUserProvider.future,
                                  );
                                  if (user == null) {
                                    setState(() => _isSubmitting = false);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Debes iniciar sesión para comentar.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final repository = ref.read(
                                    memoryRepositoryProvider,
                                  );
                                  final content = _contentController.text
                                      .trim();
                                  final subtitle = _subtitleController.text
                                      .trim();
                                  await repository.addComment(
                                    memoryId: widget.memoryId,
                                    userId: user.id,
                                    content: content,
                                    subtitle: subtitle.isNotEmpty
                                        ? subtitle
                                        : null,
                                  );
                                  ref.invalidate(
                                    memoryCommentsProvider(widget.memoryId),
                                  );
                                  if (!context.mounted) return;
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop(true);
                                  }
                                } catch (error) {
                                  setState(() => _isSubmitting = false);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No se pudo publicar: $error',
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Publicar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showCommentComposer(
  BuildContext context,
  WidgetRef ref,
  String memoryId,
) async {
  final shouldNotify = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CommentComposerDialog(memoryId: memoryId),
  );

  if (shouldNotify == true) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Comentario publicado')));
  }
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
