import 'package:flutter/material.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:mydearmap/core/widgets/memory_card.dart';

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
      appBar: AppBar(
        title: const Text('Seleccionar Recuerdos'),
        actions: [
          TextButton(
            onPressed: () => widget.onSelectionDone(_selected),
            child: const Text('Listo'),
          ),
        ],
      ),
      body: GridView.builder(
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
          final mainMedia = memory.media.isNotEmpty ? memory.media.first : null;
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
              : Positioned(
                  bottom: 40,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => _toggleMemory(memory),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.blue
                            : AppColors.buttonDisabledBackground,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                );

          return MemoryCard(
            memory: memory,
            imageUrl: imageUrl,
            overlay: overlay,
          );
        },
      ),
    );
  }
}
