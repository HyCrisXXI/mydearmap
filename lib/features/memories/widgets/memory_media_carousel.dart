import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';

class MemoryMediaCarousel extends StatefulWidget {
  const MemoryMediaCarousel({
    super.key,
    required this.media,
    this.height = 180,
    this.enableFullScreenPreview = true,
    this.prioritizeImages = false,
    this.viewportFraction = 0.78,
  });

  final List<MemoryMedia> media;
  final double height;
  final bool enableFullScreenPreview;
  final bool prioritizeImages;
  final double viewportFraction;

  @override
  State<MemoryMediaCarousel> createState() => _MemoryMediaCarouselState();
}

class _MemoryMediaCarouselState extends State<MemoryMediaCarousel> {
  late final PageController _controller;

  static const Map<MemoryMediaKind, int> _priority = {
    MemoryMediaKind.image: 0,
    MemoryMediaKind.video: 1,
    MemoryMediaKind.audio: 2,
    MemoryMediaKind.note: 3,
    MemoryMediaKind.unknown: 4,
  };

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: widget.viewportFraction);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<MemoryMedia> _sortedItems() {
    final items = [...widget.media];
    items.sort((a, b) => _priority[a.kind]!.compareTo(_priority[b.kind]!));
    if (items.length >= 3) return items;
    if (items.isEmpty) return items;
    while (items.length < 3) {
      items.add(items[items.length % widget.media.length]);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _sortedItems();
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _controller,
        itemCount: items.length,
        padEnds: items.length < 2,
        itemBuilder: (context, index) {
          final asset = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _MediaCard(
              asset: asset,
              enableFullScreenPreview: widget.enableFullScreenPreview,
            ),
          );
        },
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.asset,
    required this.enableFullScreenPreview,
  });

  final MemoryMedia asset;
  final bool enableFullScreenPreview;

  @override
  Widget build(BuildContext context) {
    switch (asset.kind) {
      case MemoryMediaKind.image:
        if (asset.publicUrl == null) {
          return const _MediaError(
            message: 'Imagen sin ruta pública disponible',
          );
        }
        return GestureDetector(
          onTap: enableFullScreenPreview
              ? () => _showFullScreenImage(context, asset.publicUrl!)
              : null,
          onLongPress: asset.publicUrl == null
              ? null
              : () => _copyToClipboard(context, asset.publicUrl!),
          child: Container(
            color: Colors.black12,
            child: Image.network(
              asset.publicUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Text('Error cargando la imagen')),
            ),
          ),
        );
      case MemoryMediaKind.video:
        return _MediaActionCard(
          icon: Icons.play_circle_outline,
          color: Colors.deepPurple,
          label: 'Video adjunto',
          hint: 'Pulsa para copiar el enlace y reproducirlo.',
          onCopy: asset.publicUrl == null
              ? null
              : () => _copyToClipboard(context, asset.publicUrl!),
        );
      case MemoryMediaKind.audio:
        return _MediaActionCard(
          icon: Icons.graphic_eq,
          color: Colors.teal,
          label: 'Audio adjunto',
          hint: 'Pulsa para copiar el enlace y escucharlo.',
          onCopy: asset.publicUrl == null
              ? null
              : () => _copyToClipboard(context, asset.publicUrl!),
        );
      case MemoryMediaKind.note:
        return Container(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              asset.content?.trim().isNotEmpty == true
                  ? asset.content!.trim()
                  : 'Nota sin contenido.',
              style: const TextStyle(height: 1.4),
            ),
          ),
        );
      case MemoryMediaKind.unknown:
        return const _MediaError(
          message: 'Este tipo de archivo no está soportado.',
        );
    }
  }

  void _showFullScreenImage(BuildContext context, String url) {
    if (!enableFullScreenPreview) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace copiado al portapapeles')),
    );
  }
}

class _MediaActionCard extends StatelessWidget {
  const _MediaActionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.hint,
    this.onCopy,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String hint;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.9)),
            textAlign: TextAlign.center,
          ),
          if (onCopy != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.link),
              label: const Text('Copiar enlace'),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    );
  }
}
