import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';

class MemoryFormCarrousel extends StatefulWidget {
  const MemoryFormCarrousel({super.key, required this.media});

  final List<MemoryMedia> media;

  @override
  State<MemoryFormCarrousel> createState() => _MemoryFormCarrouselState();
}

class _MemoryFormCarrouselState extends State<MemoryFormCarrousel> {
  late PageController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MemoryMedia> _filteredAndSortedItems() {
    // 1. Filter: Only Images and Videos
    final filtered = widget.media.where((m) {
      return m.kind == MemoryMediaKind.image || m.kind == MemoryMediaKind.video;
    }).toList();

    if (filtered.isEmpty) return const <MemoryMedia>[];

    // 2. Sort: Respect 'order' first (if present), then 'createdAt'.
    // Ignore type/kind priority.
    filtered.sort((a, b) {
      final aOrder = a.order;
      final bOrder = b.order;

      // If both have explicit order, use it
      if (aOrder != null && bOrder != null) return aOrder.compareTo(bOrder);

      // If one has order, it goes first (assuming ordered items are special/main)
      if (aOrder != null) return -1;
      if (bOrder != null) return 1;

      // Fallback: Oldest first (or whatever standard is)
      return a.createdAt.compareTo(b.createdAt);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredAndSortedItems();
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // We want the VISIBLE card to be 194px wide.
        // We have 20px padding on each side (total 40px spacing between items).
        // So the "Page" width must be 194 + 40 = 234.
        const double horizontalPadding = 20.0;
        final double itemSlotWidth =
            AppCardMemory.previewWidth + (horizontalPadding * 2);

        final fraction = itemSlotWidth / constraints.maxWidth;
        // Ensure proper fraction even if constraints are small
        final safeFraction = fraction > 1.0 ? 1.0 : fraction;

        // Initialize at the START (Index 0 = Principal)
        // With padEnds: true, this will be centered.
        final initialPage = 0;

        _controller = PageController(
          viewportFraction: safeFraction,
          initialPage: initialPage,
        );

        return SizedBox(
          height: AppCardMemory.previewHeight,
          child: ScrollConfiguration(
            behavior: const _CarouselScrollBehavior(),
            child: PageView.builder(
              controller: _controller,
              physics: const PageScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: items.length,
              padEnds: true,
              itemBuilder: (context, index) {
                final asset = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: AppCardMemory.previewWidth,
                      height: AppCardMemory.previewHeight,
                      child: _MediaCardPreview(asset: asset),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

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

class _MediaCardPreview extends StatelessWidget {
  const _MediaCardPreview({required this.asset});

  final MemoryMedia asset;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (asset.kind == MemoryMediaKind.image) {
      if (asset.previewBytes != null) {
        content = GestureDetector(
          onTap: () => _showFullScreenImage(context, bytes: asset.previewBytes),
          child: Image.memory(
            asset.previewBytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      } else if (asset.publicUrl == null) {
        content = const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      } else {
        content = GestureDetector(
          onTap: () => _showFullScreenImage(context, imageUrl: asset.publicUrl),
          child: Image.network(
            asset.publicUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator.adaptive(
                  backgroundColor: AppColors.primaryColor,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      }
    } else if (asset.kind == MemoryMediaKind.video) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black26),
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.white,
            ),
          ),
        ],
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(AppCardMemory.previewRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppCardMemory.previewRadius),
        child: content,
      ),
    );
  }

  void _showFullScreenImage(
    BuildContext context, {
    String? imageUrl,
    Uint8List? bytes,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.contain)
                  : Image.network(imageUrl!, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
