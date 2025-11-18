import 'package:flutter/material.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/core/constants/constants.dart';

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final String? imageUrl;
  final Widget? overlay;
  final VoidCallback? onTap;

  const MemoryCard({
    super.key,
    required this.memory,
    this.imageUrl,
    this.overlay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppCardMemory.width,
          maxHeight: AppCardMemory.cardWithTitleHeight,
        ),
        child: AspectRatio(
          aspectRatio: AppCardMemory.aspectRatio,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: AppCardMemory.width / AppCardMemory.height,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.all(Radius.circular(20.0)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xADDBD0BE),
                            blurRadius: 3.5,
                            spreadRadius: 0,
                            offset: Offset(0, 2.0),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppCardMemory.borderRadius,
                        ),
                        child: imageUrl != null
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.image, size: 50),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 24,
                    child: Center(
                      child: Text(
                        memory.title,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
              if (overlay != null) overlay!,
            ],
          ),
        ),
      ),
    );
  }
}
