import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:mydearmap/features/memories/widgets/memory_card.dart';

typedef MemoryOverlayBuilder =
    Widget Function(
      BuildContext context,
      Memory memory,
      bool isSelected,
      VoidCallback toggle,
    );

class MemorySelectionWidget extends StatefulWidget {
  final List<Memory> availableMemories;
  final List<Memory> selectedMemories;
  final void Function(List<Memory> selected) onSelectionDone;
  final MemoryOverlayBuilder? overlayBuilder;

  const MemorySelectionWidget({
    super.key,
    required this.availableMemories,
    required this.selectedMemories,
    required this.onSelectionDone,
    this.overlayBuilder,
  });

  @override
  State<MemorySelectionWidget> createState() => _MemorySelectionWidgetState();
}

class _MemorySelectionWidgetState extends State<MemorySelectionWidget> {
  late List<Memory> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<Memory>.from(widget.selectedMemories);
  }

  bool _isMemorySelected(Memory memory) {
    return _selected.any((m) => m.id == memory.id);
  }

  void _toggleMemory(Memory memory) {
    setState(() {
      if (_isMemorySelected(memory)) {
        _selected.removeWhere((m) => m.id == memory.id);
      } else {
        _selected.add(memory);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSizes.upperPadding,
              left: 16,
              right: 30,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: SvgPicture.asset(AppIcons.chevronLeft),
                  onPressed: () => Navigator.of(context).pop(),
                  style: AppButtonStyles.circularIconButton,
                ),
                const Text('Tus recuerdos', style: AppTextStyles.title),
                SizedBox(
                  width: 80,
                  height: AppSizes.buttonHeight,
                  child: FilledButton(
                    onPressed: () => widget.onSelectionDone(_selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      foregroundColor: AppColors.buttonForeground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadius,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Listo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: AppCardMemory.aspectRatio,
              ),
              itemCount: widget.availableMemories.length,
              itemBuilder: (context, index) {
                final memory = widget.availableMemories[index];
                final isSelected = _isMemorySelected(memory);
                final mainMedia = memory.media.isNotEmpty
                    ? memory.media.first
                    : null;
                final imageUrl = mainMedia != null && mainMedia.url != null
                    ? buildMediaPublicUrl(mainMedia.url)
                    : null;

                final overlay = widget.overlayBuilder != null
                    ? widget.overlayBuilder!(
                        context,
                        memory,
                        isSelected,
                        () => _toggleMemory(memory),
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5.5, right: 5.5),
                          child: GestureDetector(
                            onTap: () => _toggleMemory(memory),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.blue
                                    : Colors.transparent,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );

                return GestureDetector(
                  onTap: () => _toggleMemory(memory),
                  child: MemoryCard(
                    memory: memory,
                    imageUrl: imageUrl,
                    overlay: overlay,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
