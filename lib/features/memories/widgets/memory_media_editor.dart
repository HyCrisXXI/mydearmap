import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryMediaEditor extends ConsumerStatefulWidget {
  const MemoryMediaEditor({required this.memoryId, super.key});

  final String memoryId;

  @override
  ConsumerState<MemoryMediaEditor> createState() => _MemoryMediaEditorState();
}

class _MemoryMediaEditorState extends ConsumerState<MemoryMediaEditor> {
  bool _isUploading = false;

  Future<void> _addNote() async {
    final controller = TextEditingController();

    final note = await showDialog<String?>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Añadir nota'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Escribe aquí tus palabras...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (note == null || note.isEmpty) return;

    final client = Supabase.instance.client;

    try {
      setState(() => _isUploading = true);
      await client.from('media').insert({
        'memory_id': widget.memoryId,
        'media_type': kindToDatabaseValue(MemoryMediaKind.note),
        'content': note,
      });
      ref.invalidate(memoryMediaProvider(widget.memoryId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota añadida correctamente')),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyPostgrestMessage(error))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la nota: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndUpload(MemoryMediaKind kind) async {
    final allowedExtensions = switch (kind) {
      MemoryMediaKind.image => ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      MemoryMediaKind.video => ['mp4', 'mov', 'mkv', 'avi'],
      MemoryMediaKind.audio => ['mp3', 'wav', 'm4a', 'aac'],
      _ => <String>[],
    };

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo leer el archivo seleccionado'),
        ),
      );
      return;
    }

    final client = Supabase.instance.client;
    final sanitizedName = file.name.replaceAll(RegExp(r'\s+'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final folder = kindToStorageSegment(kind);
    final storagePath =
        'memories/$folder/${widget.memoryId}_${timestamp}_$sanitizedName';

    try {
      setState(() => _isUploading = true);

      await client.storage
          .from('media')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      try {
        await client.from('media').insert({
          'memory_id': widget.memoryId,
          'media_type': kindToDatabaseValue(kind),
          'url': storagePath,
        });
      } on PostgrestException {
        await client.storage.from('media').remove([storagePath]);
        rethrow;
      }

      ref.invalidate(memoryMediaProvider(widget.memoryId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${file.name} subido correctamente')),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyPostgrestMessage(error))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir el archivo: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _friendlyPostgrestMessage(PostgrestException error) {
    final lower = error.message.toLowerCase();
    if (error.code == '42501' || lower.contains('permission denied')) {
      return 'No tienes permisos para escribir en la tabla media. Revisa las políticas RLS de Supabase.';
    }
    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.paddingMedium,
          runSpacing: AppSizes.paddingMedium,
          children: [
            _MediaButton(
              icon: Icons.image,
              label: 'Imagen',
              onPressed: _isUploading
                  ? null
                  : () => _pickAndUpload(MemoryMediaKind.image),
            ),
            _MediaButton(
              icon: Icons.play_circle_fill,
              label: 'Video',
              onPressed: _isUploading
                  ? null
                  : () => _pickAndUpload(MemoryMediaKind.video),
            ),
            _MediaButton(
              icon: Icons.graphic_eq,
              label: 'Audio',
              onPressed: _isUploading
                  ? null
                  : () => _pickAndUpload(MemoryMediaKind.audio),
            ),
            _MediaButton(
              icon: Icons.note_alt,
              label: 'Nota',
              onPressed: _isUploading ? null : _addNote,
            ),
          ],
        ),
        if (_isUploading) ...[
          const SizedBox(height: AppSizes.paddingMedium),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: AppSizes.paddingMedium),
        Text(
          'Los archivos se guardan en Supabase dentro de la carpeta media/memories.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}

class _MediaButton extends StatelessWidget {
  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
