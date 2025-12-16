import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/core/utils/media_url.dart';

class MemoryInfoCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;

  const MemoryInfoCard({super.key, required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    final images = memory.media
        .where((m) => m.type == MediaType.image && m.url != null)
        .toList();
    if (images.isNotEmpty) {
      images.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      imageUrl = buildMediaPublicUrl(images.first.url);
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen preview
                if (imageUrl != null)
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textGray,
                    ),
                  ),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        memory.title,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w500, // w500 es Medium
                          color: AppColors.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM yyyy').format(memory.happenedAt),
                        style: AppTextStyles.text.copyWith(
                          fontSize: 13,
                          color: AppColors.textGray,
                        ),
                      ),
                      if (memory.description != null &&
                          memory.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          memory.description!,
                          style: AppTextStyles.text.copyWith(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
