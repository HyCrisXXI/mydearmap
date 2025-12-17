import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'timecapsule_create_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/widgets/pulse_button.dart';

class TimeCapsuleView extends ConsumerWidget {
  const TimeCapsuleView({super.key, required this.capsuleId});

  final String capsuleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsuleAsync = ref.watch(timeCapsuleProvider(capsuleId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppIcons.profileBG),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            top: false,
            child: capsuleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (capsule) {
                if (capsule == null) {
                  return const Center(child: Text('Cápsula no encontrada'));
                }

                return Column(
                  children: [
                    // Custom Header
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSizes.upperPadding,
                        left: 20,
                        right: 20,
                        bottom: 10,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PulseButton(
                              child: IconButton(
                                icon: SvgPicture.asset(AppIcons.chevronLeft),
                                onPressed: () {
                                  final navigator = Navigator.of(context);
                                  if (navigator.canPop()) {
                                    navigator.pop();
                                  } else {
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pushReplacementNamed('/notifications');
                                  }
                                },
                                style: AppButtonStyles.circularIconButton,
                              ),
                            ),
                          ),
                          Text(
                            capsule.title,
                            style: AppTextStyles.title,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: PulseButton(
                              child: IconButton(
                                icon: SvgPicture.asset(AppIcons.pencil),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TimeCapsuleCreateView(
                                        capsuleId: capsuleId,
                                      ),
                                    ),
                                  );
                                },
                                style: AppButtonStyles.circularIconButton,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (capsule.description != null) ...[
                              Text(
                                capsule.description!,
                                style: AppTextStyles.subtitle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: capsule.isClosed
                                    ? Colors.redAccent.withAlpha(25)
                                    : Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: capsule.isClosed
                                      ? Colors.redAccent
                                      : Colors.green,
                                ),
                              ),
                              child: Text(
                                capsule.isClosed ? 'Cerrada' : 'Abierta',
                                style: TextStyle(
                                  color: capsule.isClosed
                                      ? Colors.redAccent
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Recuerdos',
                              style: AppTextStyles.subtitle,
                            ),
                            const SizedBox(height: 16),
                            _MemoriesList(
                              capsuleId: capsuleId,
                              isLocked: capsule.isClosed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoriesList extends ConsumerWidget {
  const _MemoriesList({required this.capsuleId, required this.isLocked});

  final String capsuleId;
  final bool isLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(timeCapsuleRepositoryProvider);
    return FutureBuilder<List<Memory>>(
      future: repo.getTimeCapsuleMemories(capsuleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        final memories = snapshot.data ?? [];
        if (memories.isEmpty) {
          return const Text('Sin recuerdos asociados.');
        }
        return Column(
          children: memories
              .map((memory) => _MemoryTile(memory: memory, isLocked: isLocked))
              .toList(),
        );
      },
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.memory, required this.isLocked});

  final Memory memory;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 0,
      leading: _MemoryThumbnail(memory: memory),
      title: Text(memory.title),
      subtitle: isLocked ? const Text('Disponible al abrir la cápsula') : null,
      trailing: Icon(isLocked ? Icons.lock_outline : Icons.chevron_right),
      onTap: isLocked
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MemoryDetailView(memoryId: memory.id!),
                ),
              );
            },
    );
  }
}

class _MemoryThumbnail extends StatelessWidget {
  const _MemoryThumbnail({required this.memory});

  final Memory memory;

  Media? _pickDisplayMedia() {
    Media? fallback;
    for (final media in memory.media) {
      final url = media.url;
      if (url == null || url.isEmpty) continue;
      fallback ??= media;
      if (media.type == MediaType.image) return media;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final media = _pickDisplayMedia();
    final imageUrl = buildMediaPublicUrl(media?.url);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Icon(
        Icons.photo,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );

    if (imageUrl == null) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}
