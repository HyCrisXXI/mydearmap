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

  const MemoryCard({
    super.key,
    required this.memory,
    this.imageUrl,
    this.overlay,
    this.onTap,
    this.size = MemoryCardSize.standard,
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
        child: SizedBox(
          width: cardWidth,
          height: totalHeight,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- 1. PARTE SUPERIOR (IMAGEN) ---
                  SizedBox(
                    height: imageHeight,
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

                  // --- 2. PARTE INFERIOR (FRANJA BLANCA CON TEXTO) ---
                  Container(
                    height: AppSizes.memoryFooterHeight,
                    decoration: AppDecorations.memoryCardBottom,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    alignment: Alignment.center,
                    child: Text(
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
                ],
              ),

              // --- OVERLAY (SI EXISTE) ---
              if (overlay != null) Positioned.fill(child: overlay!),
            ],
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
