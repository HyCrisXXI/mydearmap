import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/media.dart'
    show MediaType, mediaOrderStride, mediaTypeOrderBase;
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingMemoryMediaDraft {
  PendingMemoryMediaDraft({
    required this.kind,
    required this.label,
    required Future<void> Function(String memoryId) uploader,
    this.previewBytes,
  }) : _uploader = uploader;

  final MemoryMediaKind kind;
  final String label;
  final Uint8List? previewBytes;
  final Future<void> Function(String memoryId) _uploader;

  Future<void> upload(String memoryId) => _uploader(memoryId);
}

class MemoryMediaEditorController {
  _MemoryMediaEditorState? _state;

  Future<void> commitPendingChanges({required String memoryId}) async {
    await _state?._commitPendingDrafts(memoryId);
  }

  bool get hasPendingDrafts => _state?._hasPendingDrafts ?? false;

  List<PendingMemoryMediaDraft> get drafts =>
      List.unmodifiable(_state?._pendingDrafts ?? const []);

  void _attach(_MemoryMediaEditorState state) => _state = state;

  void _detach(_MemoryMediaEditorState state) {
    if (_state == state) _state = null;
  }

  void reorderDraft(int oldIndex, int newIndex) =>
      _state?._reorderDraft(oldIndex, newIndex);

  void removeDraftAt(int index) => _state?._removeDraftAt(index);
}

class MemoryMediaEditor extends ConsumerStatefulWidget {
  const MemoryMediaEditor({
    super.key,
    required this.memoryId,
    this.controller,
    this.deferUploads = false,
    this.onPendingDraftsChanged,
  });

  final String memoryId;
  final MemoryMediaEditorController? controller;
  final bool deferUploads;
  final ValueChanged<List<PendingMemoryMediaDraft>>? onPendingDraftsChanged;

  @override
  ConsumerState<MemoryMediaEditor> createState() => _MemoryMediaEditorState();
}

class _MemoryMediaEditorState extends ConsumerState<MemoryMediaEditor> {
  bool _isUploading = false;
  final List<PendingMemoryMediaDraft> _pendingDrafts =
      <PendingMemoryMediaDraft>[];

  bool get _hasPendingDrafts => _pendingDrafts.isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant MemoryMediaEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  void _registerDraft(PendingMemoryMediaDraft draft) {
    setState(() => _pendingDrafts.add(draft));
    widget.onPendingDraftsChanged?.call(List.unmodifiable(_pendingDrafts));
  }

  void _clearDraft(PendingMemoryMediaDraft draft) {
    setState(() => _pendingDrafts.remove(draft));
    widget.onPendingDraftsChanged?.call(List.unmodifiable(_pendingDrafts));
  }

  void _reorderDraft(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex >= _pendingDrafts.length ||
        newIndex >= _pendingDrafts.length) {
      return;
    }
    setState(() {
      final draft = _pendingDrafts.removeAt(oldIndex);
      _pendingDrafts.insert(newIndex, draft);
    });
    widget.onPendingDraftsChanged?.call(List.unmodifiable(_pendingDrafts));
  }

  void _removeDraftAt(int index) {
    if (index < 0 || index >= _pendingDrafts.length) return;
    setState(() {});
    widget.onPendingDraftsChanged?.call(List.unmodifiable(_pendingDrafts));
  }

  Future<void> _commitPendingDrafts(String memoryId) async {
    if (_pendingDrafts.isEmpty) return;
    final drafts = List<PendingMemoryMediaDraft>.from(_pendingDrafts);
    for (final draft in drafts) {
      await draft.upload(memoryId);
      _clearDraft(draft);
    }
  }

  Future<void> _uploadOrDefer({
    required MemoryMediaKind kind,
    required String label,
    required Future<void> Function(String memoryId) uploader,
    Uint8List? previewBytes,
  }) async {
    if (!widget.deferUploads) {
      await uploader(widget.memoryId);
      return;
    }
    _registerDraft(
      PendingMemoryMediaDraft(
        kind: kind,
        label: label,
        uploader: uploader,
        previewBytes: previewBytes,
      ),
    );
  }

  Future<void> _handlePickedFile(
    MemoryMediaKind kind,
    Future<FilePickerResult?> Function() picker,
  ) async {
    final result = await picker();
    final file = result?.files.first;
    if (file == null) return;

    await _uploadOrDefer(
      kind: kind,
      label: file.name,
      uploader: (memoryId) => _uploadPickedFile(kind, file, memoryId),
      previewBytes: kind == MemoryMediaKind.image ? file.bytes : null,
    );
  }

  Future<void> _handlePickedXFile(
    MemoryMediaKind kind,
    Future<XFile?> Function() picker,
  ) async {
    final file = await picker();
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final name = file.name;

    await _uploadOrDefer(
      kind: kind,
      label: name,
      uploader: (memoryId) => _uploadPickedXFile(kind, file, bytes, memoryId),
      previewBytes: kind == MemoryMediaKind.image ? bytes : null,
    );
  }

  Future<void> _uploadPickedFile(
    MemoryMediaKind kind,
    PlatformFile file,
    String memoryId,
  ) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('No se pudo leer el archivo seleccionado.');
    }
    await _performUpload(kind, file.name, file.extension, bytes, memoryId);
  }

  Future<void> _uploadPickedXFile(
    MemoryMediaKind kind,
    XFile file,
    Uint8List bytes,
    String memoryId,
  ) async {
    final name = file.name;
    final ext = name.split('.').last;
    await _performUpload(kind, name, ext, bytes, memoryId);
  }

  Future<void> _performUpload(
    MemoryMediaKind kind,
    String fileName,
    String? fileExtension,
    Uint8List bytes,
    String memoryId,
  ) async {
    final client = Supabase.instance.client;
    final sanitizedName = _buildSanitizedFileName(fileName, fileExtension);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final folder = kindToStorageSegment(kind);
    final storagePath =
        'memories/$folder/${memoryId}_${timestamp}_$sanitizedName';

    try {
      setState(() => _isUploading = true);
      final nextOrder = await _nextOrderValue(memoryId, kind);

      await client.storage
          .from('media')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      try {
        await client.from('media').insert({
          'memory_id': memoryId,
          'media_type': kindToDatabaseValue(kind),
          'url': storagePath,
          'order': nextOrder,
        });
      } on PostgrestException {
        await client.storage.from('media').remove([storagePath]);
        rethrow;
      }

      ref.invalidate(memoryMediaProvider(memoryId));
      ref.invalidate(userMemoriesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$fileName subido correctamente')));
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

  String _buildSanitizedFileName(String fileName, String? extension) {
    final original = fileName.trim();
    final ext = extension ?? '';
    String namePart;
    if (original.isEmpty) {
      namePart = 'file';
    } else {
      final dotIndex = original.lastIndexOf('.');
      if (dotIndex > 0 && dotIndex < original.length - 1) {
        namePart = original.substring(0, dotIndex);
      } else {
        namePart = original;
      }
    }

    final safeName = _sanitizePathSegment(namePart);
    final safeExt = _sanitizePathSegment(ext, allowEmpty: true);

    if (safeExt.isNotEmpty) {
      return '$safeName.$safeExt';
    }
    return safeName;
  }

  String _sanitizePathSegment(String input, {bool allowEmpty = false}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return allowEmpty ? '' : 'file';
    }

    final asciiOnly = trimmed.replaceAll(RegExp(r'[^\x00-\x7F]'), '_');
    final allowed = asciiOnly.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    final collapsed = allowed.replaceAll(RegExp(r'_+'), '_');
    final trimmedUnderscore = collapsed.replaceAll(RegExp(r'^_+|_+$'), '');
    final result = trimmedUnderscore.isEmpty
        ? (allowEmpty ? '' : 'file')
        : trimmedUnderscore;
    if (result.isEmpty) return result;
    return result.length > 96 ? result.substring(0, 96) : result;
  }

  Future<int> _nextOrderValue(String memoryId, MemoryMediaKind kind) async {
    final client = Supabase.instance.client;
    final base = _orderBaseForKind(kind);
    try {
      final response = await client
          .from('media')
          .select('order')
          .eq('memory_id', memoryId)
          .eq('media_type', kindToDatabaseValue(kind))
          .order('order', ascending: false)
          .limit(1);

      final rows = response as List<dynamic>;
      if (rows.isEmpty) return base;

      final map = rows.first as Map<String, dynamic>;
      final value = map['order'];
      final parsed = value is int ? value : int.tryParse('$value');
      if (parsed == null) return base;
      final normalized = _normalizeOrderForKind(parsed, base);
      final relative = normalized - base;
      final nextRelative = relative >= 0 ? relative + 1 : 0;
      if (nextRelative >= mediaOrderStride) {
        return base + mediaOrderStride - 1;
      }
      return base + nextRelative;
    } catch (_) {
      return base;
    }
  }

  int _orderBaseForKind(MemoryMediaKind kind) {
    switch (kind) {
      case MemoryMediaKind.image:
        return mediaTypeOrderBase(MediaType.image);
      case MemoryMediaKind.video:
        return mediaTypeOrderBase(MediaType.video);
      case MemoryMediaKind.audio:
        return mediaTypeOrderBase(MediaType.audio);
      case MemoryMediaKind.unknown:
      default:
        return mediaTypeOrderBase(MediaType.note) + mediaOrderStride;
    }
  }

  int _normalizeOrderForKind(int order, int base) {
    if (order < base) {
      final relative = order >= 0 ? order : 0;
      return base + relative;
    }
    if (order >= base + mediaOrderStride) {
      final relative = (order - base) % mediaOrderStride;
      return base + relative;
    }
    return order;
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
    final children = <Widget>[
      Wrap(
        spacing: AppSizes.paddingMedium,
        runSpacing: AppSizes.paddingMedium,
        children: [
          _MediaButton(
            icon: Icons.image,
            label: 'Imagen',
            onPressed: _isUploading
                ? null
                : () => _handlePickedXFile(
                    MemoryMediaKind.image,
                    () => ImagePicker().pickImage(source: ImageSource.gallery),
                  ),
          ),
          _MediaButton(
            icon: Icons.play_circle_fill,
            label: 'Video',
            onPressed: _isUploading
                ? null
                : () => _handlePickedXFile(
                    MemoryMediaKind.video,
                    () => ImagePicker().pickVideo(source: ImageSource.gallery),
                  ),
          ),
          _MediaButton(
            icon: Icons.graphic_eq,
            label: 'Audio',
            onPressed: _isUploading
                ? null
                : () => _handlePickedFile(
                    MemoryMediaKind.audio,
                    () => FilePicker.platform.pickFiles(
                      allowMultiple: false,
                      type: FileType.custom,
                      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
                      withData: true,
                    ),
                  ),
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
    ];

    if (_hasPendingDrafts) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.paddingSmall),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _pendingDrafts
                .map(
                  (draft) => Chip(
                    label: Text('${_kindLabel(draft.kind)} · ${draft.label}'),
                    backgroundColor: Colors.orange.shade100,
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String _kindLabel(MemoryMediaKind kind) {
    switch (kind) {
      case MemoryMediaKind.image:
        return 'Imagen';
      case MemoryMediaKind.video:
        return 'Video';
      case MemoryMediaKind.audio:
        return 'Audio';
      case MemoryMediaKind.unknown:
      default:
        return 'Archivo';
    }
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
