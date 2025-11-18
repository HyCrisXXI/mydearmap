import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/widgets/memory_card.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/utils/media_url.dart';

typedef MemoryTapCallback = void Function(Memory memory);

class MemoriesGrid extends StatelessWidget {
  final List<Memory> memories;
  final MemoryTapCallback? onMemoryTap;
  final bool showFavoriteOverlay;
  final EdgeInsets gridPadding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const MemoriesGrid({
    super.key,
    required this.memories,
    this.onMemoryTap,
    this.showFavoriteOverlay = true,
    this.gridPadding = const EdgeInsets.all(AppSizes.paddingLarge),
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    // Ordena favoritos primero, luego por fecha
    final sorted = [...memories]
      ..sort((a, b) {
        final aFav = a.isFavorite;
        final bFav = b.isFavorite;
        if (aFav == bFav) {
          return b.happenedAt.compareTo(a.happenedAt);
        }
        return bFav ? 1 : -1;
      });

    return GridView.builder(
      padding: gridPadding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: AppCardMemory.aspectRatio,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final memory = sorted[index];
        final mainMedia = memory.media.isNotEmpty ? memory.media.first : null;
        final imageUrl = mainMedia != null && mainMedia.url != null
            ? buildMediaPublicUrl(mainMedia.url)
            : null;

        return _FavoriteMemoryCard(
          memory: memory,
          imageUrl: imageUrl,
          onTap: onMemoryTap != null ? () => onMemoryTap!(memory) : null,
          showFavoriteOverlay: showFavoriteOverlay,
        );
      },
    );
  }
}

class _FavoriteMemoryCard extends StatefulWidget {
  final Memory memory;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool showFavoriteOverlay;

  const _FavoriteMemoryCard({
    required this.memory,
    this.imageUrl,
    this.onTap,
    this.showFavoriteOverlay = true,
  });

  @override
  State<_FavoriteMemoryCard> createState() => _FavoriteMemoryCardState();
}

class _FavoriteMemoryCardState extends State<_FavoriteMemoryCard> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.memory.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    final ref = ProviderScope.containerOf(context, listen: false);
    return GestureDetector(
      onTap: widget.onTap,
      child: MemoryCard(
        memory: widget.memory,
        imageUrl: widget.imageUrl,
        overlay: widget.showFavoriteOverlay
            ? Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () async {
                    final userId = ref.read(currentUserProvider).value?.id;
                    if (userId == null || widget.memory.id == null) return;
                    setState(() => isFavorite = !isFavorite); // Optimista
                    final repo = ref.read(memoryRepositoryProvider);
                    await repo.setFavorite(
                      memoryId: widget.memory.id!,
                      userId: userId,
                      isFavorite: isFavorite,
                    );
                  },
                  child: Image.asset(
                    isFavorite ? AppIcons.starFilled : AppIcons.star,
                    width: 23,
                    height: 22,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
