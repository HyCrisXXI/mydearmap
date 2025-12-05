import 'package:flutter/material.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/core/constants/constants.dart';

enum MemoryCardSize { standard, big }

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final String? imageUrl;
  final Widget? overlay;
  final VoidCallback? onTap;
  final MemoryCardSize size;
  final Widget? titleWidget;

  const MemoryCard({
    super.key,
    required this.memory,
    this.imageUrl,
    this.overlay,
    this.onTap,
    this.size = MemoryCardSize.standard,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Determinamos dimensiones según el tamaño
    final double cardWidth = size == MemoryCardSize.big
        ? AppCardMemory.bigWidth
        : AppCardMemory.width;

    final double imageHeight = size == MemoryCardSize.big
        ? AppCardMemory.bigImageHeight
        : AppCardMemory.height;

    // La altura total es la imagen + el footer
    final double totalHeight = imageHeight + AppSizes.memoryFooterHeight;

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppCardMemory.borderRadius),
          child: SizedBox(
            width: cardWidth,
            height: totalHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: AppDecorations.memoryCardTop,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppSizes.memoryRadiusTop),
                          ),
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: AppSizes.memoryFooterHeight,
                      child: Container(
                        decoration: AppDecorations.memoryCardBottom,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.center,
                        child:
                            titleWidget ??
                            Text(
                              memory.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.textButton.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
                if (overlay != null) Positioned.fill(child: overlay!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }
}
