import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';

class MemoryMediaCarousel extends StatefulWidget {
  const MemoryMediaCarousel({
    required this.media,
    this.emptyState,
    this.height = 220,
    this.prioritizeImages = true,
    this.enableFullScreenPreview = true,
    super.key,
  });

  final List<MemoryMedia> media;
  final Widget? emptyState;
  final double height;
  final bool prioritizeImages;
  final bool enableFullScreenPreview;

  @override
  State<MemoryMediaCarousel> createState() => _MemoryMediaCarouselState();
}

class _MemoryMediaCarouselState extends State<MemoryMediaCarousel> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  List<MemoryMedia> get _items {
    if (!widget.prioritizeImages) return widget.media;
    final ordered = [...widget.media]
      ..sort((a, b) => _priority(a).compareTo(_priority(b)));
    return ordered;
  }

  int _priority(MemoryMedia asset) {
    switch (asset.kind) {
      case MemoryMediaKind.image:
        return 0;
      case MemoryMediaKind.video:
        return 1;
      case MemoryMediaKind.audio:
        return 2;
      case MemoryMediaKind.note:
        return 3;
      case MemoryMediaKind.unknown:
        return 4;
    }
  }

  @override
  void didUpdateWidget(covariant MemoryMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.media.length) {
      _page = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace copiado al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return widget.emptyState ??
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Añade fotos, videos, audios o notas a este recuerdo.',
            ),
          );
    }

    final items = _items;

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            child: PageView.builder(
              controller: _controller,
              itemCount: items.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) {
                final asset = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildAssetCard(asset),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _page == index ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: _page == index
                    ? AppColors.primaryColor
                    : AppColors.primaryColor.withValues(alpha: .3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(MemoryMedia asset) {
    switch (asset.kind) {
      case MemoryMediaKind.image:
        if (asset.publicUrl == null) {
          return const _MediaError(
            message: 'Imagen sin ruta pública disponible',
          );
        }
        return GestureDetector(
          onTap: widget.enableFullScreenPreview
              ? () => _showFullScreenImage(asset.publicUrl!)
              : null,
          onLongPress: () => _copyToClipboard(asset.publicUrl!),
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
              : () => _copyToClipboard(asset.publicUrl!),
        );
      case MemoryMediaKind.audio:
        return _MediaActionCard(
          icon: Icons.graphic_eq,
          color: Colors.teal,
          label: 'Audio adjunto',
          hint: 'Pulsa para copiar el enlace y escucharlo.',
          onCopy: asset.publicUrl == null
              ? null
              : () => _copyToClipboard(asset.publicUrl!),
        );
      case MemoryMediaKind.note:
        return Container(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          decoration: BoxDecoration(
            color: AppColors.accentColor.withValues(alpha: .1),
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

  void _showFullScreenImage(String url) {
    if (!widget.enableFullScreenPreview) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
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
        color: color.withValues(alpha: .12),
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
            ).textTheme.bodySmall?.copyWith(color: color.withValues(alpha: .9)),
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
        color: Colors.redAccent.withValues(alpha: .12),
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
