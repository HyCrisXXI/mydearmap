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
      appBar: AppBar(
        leading: BackButton(
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
        ),
        title: const Text('Detalle de Cápsula'),
        actions: [
          PulseButton(
            child: IconButton(
              icon: SvgPicture.asset(AppIcons.pencil),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TimeCapsuleCreateView(capsuleId: capsuleId),
                  ),
                );
              },
              style: AppButtonStyles.circularIconButton,
            ),
          ),
        ],
      ),
      body: capsuleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (capsule) {
          if (capsule == null) {
            return const Center(child: Text('Cápsula no encontrada'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (capsule.description != null) ...[
                  const SizedBox(height: 8),
                  Text(capsule.description!),
                ],
                const SizedBox(height: 16),
                Text('Estado: ${capsule.isClosed ? 'Cerrada' : 'Abierta'}'),
                const SizedBox(height: 16),
                const Text(
                  'Recuerdos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _MemoriesList(
                  capsuleId: capsuleId,
                  isLocked: capsule.isClosed,
                ),
              ],
            ),
          );
        },
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
              .map(
                (memory) => _MemoryTile(
                  memory: memory,
                  isLocked: isLocked,
                ),
              )
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
      subtitle:
          isLocked ? const Text('Disponible al abrir la cápsula') : null,
      trailing: Icon(
        isLocked ? Icons.lock_outline : Icons.chevron_right,
      ),
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
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
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
        errorBuilder: (_, __, ___) => placeholder,
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
