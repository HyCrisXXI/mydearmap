import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/features/timecapsules/views/timecapsules_view.dart';
import 'package:mydearmap/core/widgets/memory_card.dart'; // Importa MemoryCard
import 'package:mydearmap/core/utils/media_url.dart'; // Para buildMediaPublicUrl

class MemoriesView extends ConsumerWidget {
  const MemoriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(userMemoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis recuerdos'),
        actions: [
          IconButton(
            icon: Image.asset(AppIcons.timer),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimeCapsulesView()),
              );
            },
            style: AppButtonStyles.circularIconButton,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: memoriesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (error, _) => Center(
            child: Text('No se pudieron cargar los recuerdos: $error'),
          ),
          data: (memories) {
            if (memories.isEmpty) {
              return const Center(
                child: Text('Todavía no has guardado ningún recuerdo.'),
              );
            }

            final sorted = [...memories]
              ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: AppCardMemory.aspectRatio,
              ),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final memory = sorted[index];
                final memoryId = memory.id ?? '';

                if (memoryId.isEmpty) {
                  return const _MemoryCardError(
                    message: 'El identificador del recuerdo es inválido.',
                  );
                }

                final mainMedia = memory.media.isNotEmpty
                    ? memory.media.first
                    : null;
                final imageUrl = mainMedia != null && mainMedia.url != null
                    ? buildMediaPublicUrl(mainMedia.url)
                    : null;

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MemoryDetailView(memoryId: memoryId),
                      ),
                    );
                  },
                  child: MemoryCard(memory: memory, imageUrl: imageUrl),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: 1, // El índice de los recuerdos
      ),
    );
  }
}

class _MemoryCardError extends StatelessWidget {
  const _MemoryCardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        color: Colors.redAccent.withValues(alpha: .12),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
      ),
    );
  }
}
