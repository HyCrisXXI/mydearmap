import 'package:flutter/gestures.dart'; // Necesario para el ScrollBehavior
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
  final bool showFeatured;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const MemoriesGrid({
    super.key,
    required this.memories,
    this.onMemoryTap,
    this.showFavoriteOverlay = true,
    this.gridPadding = const EdgeInsets.all(AppSizes.paddingLarge),
    this.showFeatured = false,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Filtrar destacados (favoritos)
    final featuredMemories = memories.where((m) => m.isFavorite).toList();

    // 2. Ordenar lista general: favoritos primero, luego por fecha
    final sortedMemories = [...memories]
      ..sort((a, b) {
        final aFav = a.isFavorite;
        final bFav = b.isFavorite;
        if (aFav == bFav) {
          return b.happenedAt.compareTo(a.happenedAt);
        }
        return bFav ? 1 : -1;
      });

    // --- FIX: Only use CustomScrollView if NOT inside another scrollable ---
    // If shrinkWrap is true, always use a Wrap (never CustomScrollView)
    if (shrinkWrap) {
      return Padding(
        padding: gridPadding,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final memory in sortedMemories)
              SizedBox(
                width:
                    (MediaQuery.of(context).size.width -
                        gridPadding.horizontal -
                        12) /
                    2,
                child: _FavoriteMemoryCard(
                  memory: memory,
                  imageUrl:
                      memory.media.isNotEmpty && memory.media.first.url != null
                      ? buildMediaPublicUrl(memory.media.first.url)
                      : null,
                  onTap: onMemoryTap != null
                      ? () => onMemoryTap!(memory)
                      : null,
                  showFavoriteOverlay: showFavoriteOverlay,
                  size: MemoryCardSize.standard,
                ),
              ),
          ],
        ),
      );
    }

    // --- Only use CustomScrollView if shrinkWrap is false (full screen) ---
    return LayoutBuilder(
      builder: (context, constraints) {
        // If height is unbounded, fallback to Wrap (prevents error)
        if (!constraints.hasBoundedHeight) {
          return Padding(
            padding: gridPadding,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final memory in sortedMemories)
                  SizedBox(
                    width:
                        (MediaQuery.of(context).size.width -
                            gridPadding.horizontal -
                            12) /
                        2,
                    child: _FavoriteMemoryCard(
                      memory: memory,
                      imageUrl:
                          memory.media.isNotEmpty &&
                              memory.media.first.url != null
                          ? buildMediaPublicUrl(memory.media.first.url)
                          : null,
                      onTap: onMemoryTap != null
                          ? () => onMemoryTap!(memory)
                          : null,
                      showFavoriteOverlay: showFavoriteOverlay,
                      size: MemoryCardSize.standard,
                    ),
                  ),
              ],
            ),
          );
        }

        // --- Normal CustomScrollView for full screen usage ---
        return CustomScrollView(
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- SECCIÓN DESTACADOS ---
            if (showFeatured && featuredMemories.isNotEmpty) ...[
              // Header Destacados
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Row(
                    children: [
                      const Text("Destacados", style: AppTextStyles.subtitle),
                      const SizedBox(width: 8),
                      Image.asset(AppIcons.blackStar, width: 24, height: 24),
                    ],
                  ),
                ),
              ),

              // Carrusel Horizontal
              SliverToBoxAdapter(
                child: _FeaturedCarousel(
                  memories: featuredMemories,
                  onTap: onMemoryTap,
                  showFavoriteOverlay: showFavoriteOverlay,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // --- SECCIÓN TODOS ---
            if (showFeatured)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text("Todos", style: AppTextStyles.subtitle),
                      const SizedBox(width: 8),
                      Image.asset(AppIcons.folderOpen, width: 24, height: 24),
                    ],
                  ),
                ),
              ),

            // --- GRID DE TODOS LOS RECUERDOS ---
            SliverPadding(
              padding: gridPadding,
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: AppCardMemory.aspectRatio,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final memory = sortedMemories[index];
                  final mainMedia = memory.media.isNotEmpty
                      ? memory.media.first
                      : null;
                  final imageUrl = mainMedia?.url != null
                      ? buildMediaPublicUrl(mainMedia!.url)
                      : null;

                  return _FavoriteMemoryCard(
                    memory: memory,
                    imageUrl: imageUrl,
                    onTap: onMemoryTap != null
                        ? () => onMemoryTap!(memory)
                        : null,
                    showFavoriteOverlay: showFavoriteOverlay,
                    size: MemoryCardSize.standard,
                  );
                }, childCount: sortedMemories.length),
              ),
            ),

            // Espacio extra al final
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }
}

// --- WIDGET DEL CARRUSEL DESTACADO ---
class _FeaturedCarousel extends StatefulWidget {
  final List<Memory> memories;
  final MemoryTapCallback? onTap;
  final bool showFavoriteOverlay;

  const _FeaturedCarousel({
    required this.memories,
    this.onTap,
    required this.showFavoriteOverlay,
  });

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  late PageController _pageController;
  final int _initialPage = 1000;

  @override
  void initState() {
    super.initState();
    // CORRECCIÓN: 0.6 es el valor ideal para ver la central + trozos de las laterales.
    // Con 0.8 se iban fuera de pantalla.
    _pageController = PageController(
      viewportFraction: 0.6,
      initialPage: _initialPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppCardMemory.bigTotalHeight,
      // ESTA ES LA CLAVE: Permitir arrastrar con ratón y touch
      child: ScrollConfiguration(
        behavior: const _CarouselScrollBehavior(),
        child: PageView.builder(
          // CORRECCIÓN: Clip.none permite pintar fuera del área asignada,
          // esencial para ver las tarjetas laterales sin cortes raros.
          clipBehavior: Clip.none,
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.memories.length * 10000,
          itemBuilder: (context, index) {
            final int realIndex = index % widget.memories.length;
            final memory = widget.memories[realIndex];

            final mainMedia = memory.media.isNotEmpty
                ? memory.media.first
                : null;
            final imageUrl = mainMedia?.url != null
                ? buildMediaPublicUrl(mainMedia!.url)
                : null;

            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  // Suavizado de escala: Mantenemos 0.85 para que las de los lados sean un pelín más pequeñas
                  value = (1 - (value.abs() * 0.2)).clamp(0.85, 1.0);
                } else {
                  value = (index == _initialPage) ? 1.0 : 0.85;
                }

                return Center(
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: _FavoriteMemoryCard(
                memory: memory,
                imageUrl: imageUrl,
                onTap: widget.onTap != null
                    ? () => widget.onTap!(memory)
                    : null,
                showFavoriteOverlay: widget.showFavoriteOverlay,
                size: MemoryCardSize.big,
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- CONFIGURACIÓN DE SCROLL (CLAVE PARA WEB/DESKTOP) ---
class _CarouselScrollBehavior extends MaterialScrollBehavior {
  const _CarouselScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };
}

// --- TARJETA CON LÓGICA DE FAVORITOS ---
class _FavoriteMemoryCard extends StatefulWidget {
  final Memory memory;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool showFavoriteOverlay;
  final MemoryCardSize size;

  const _FavoriteMemoryCard({
    required this.memory,
    this.imageUrl,
    this.onTap,
    this.showFavoriteOverlay = true,
    required this.size,
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
  void didUpdateWidget(covariant _FavoriteMemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memory.isFavorite != widget.memory.isFavorite) {
      isFavorite = widget.memory.isFavorite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = ProviderScope.containerOf(context, listen: false);

    return MemoryCard(
      memory: widget.memory,
      imageUrl: widget.imageUrl,
      size: widget.size,
      onTap: widget.onTap,
      overlay: widget.showFavoriteOverlay
          ? Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 10),
                child: IconButton(
                  style: AppButtonStyles.circularIconButton,
                  onPressed: () async {
                    final userId = ref.read(currentUserProvider).value?.id;
                    if (userId == null || widget.memory.id == null) return;

                    setState(() => isFavorite = !isFavorite);

                    final repo = ref.read(memoryRepositoryProvider);
                    await repo.setFavorite(
                      memoryId: widget.memory.id!,
                      userId: userId,
                      isFavorite: isFavorite,
                    );
                  },
                  icon: Image.asset(
                    isFavorite ? AppIcons.starFilled : AppIcons.star,
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
