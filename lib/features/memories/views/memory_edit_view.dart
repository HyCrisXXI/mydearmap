// lib/features/memories/views/memory_edit_view.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/widgets/app_form_buttons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/memories/controllers/memory_controller.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/memories/widgets/memory_form.dart';
import 'package:mydearmap/features/memories/widgets/memory_media_editor.dart'
    show
        MemoryMediaEditor,
        MemoryMediaEditorController,
        PendingMemoryMediaDraft;
import 'package:mydearmap/features/memories/widgets/memory_media_carousel.dart';

final _memoryByIdProvider = FutureProvider.family<Memory, String>((
  ref,
  memoryId,
) async {
  final memoryController = ref.read(memoryControllerProvider.notifier);
  final memory = await memoryController.getMemoryById(memoryId);

  if (memory == null) {
    throw Exception('Recuerdo con ID "$memoryId" no encontrado.');
  }
  return memory;
});

const LatLng _defaultLocation = LatLng(39.4699, -0.3763);

enum MemoryUpsertMode { create, edit }

class MemoryUpsertView extends ConsumerStatefulWidget {
  const MemoryUpsertView._({
    super.key,
    required this.mode,
    this.memoryId,
    this.initialLocation,
  }) : assert(
         mode == MemoryUpsertMode.edit
             ? memoryId != null
             : initialLocation != null,
       );

  factory MemoryUpsertView.create({
    Key? key,
    required LatLng initialLocation,
  }) => MemoryUpsertView._(
    key: key,
    mode: MemoryUpsertMode.create,
    initialLocation: initialLocation,
  );

  factory MemoryUpsertView.edit({Key? key, required String memoryId}) =>
      MemoryUpsertView._(
        key: key,
        mode: MemoryUpsertMode.edit,
        memoryId: memoryId,
      );

  final MemoryUpsertMode mode;
  final String? memoryId;
  final LatLng? initialLocation;

  @override
  ConsumerState<MemoryUpsertView> createState() => _MemoryUpsertViewState();
}

class _MemoryUpsertViewState extends ConsumerState<MemoryUpsertView> {
  DateTime? _selectedDate;
  LatLng _currentLocation = _defaultLocation;
  final Set<String> _deletingMediaIds = <String>{};

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _mapController = MapController();

  final MemoryMediaEditorController _mediaEditorController =
      MemoryMediaEditorController();
  List<PendingMemoryMediaDraft> _pendingMediaDrafts =
      const <PendingMemoryMediaDraft>[];
  bool _committingMedia = false;
  bool _isInitialized = false;
  String? _resolvedMemoryId;

  @override
  void initState() {
    super.initState();
    if (widget.mode == MemoryUpsertMode.create) {
      _currentLocation = widget.initialLocation ?? _defaultLocation;
      _isInitialized = true;
    } else {
      _resolvedMemoryId = widget.memoryId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _initializeControllers(Memory memory) {
    if (_isInitialized) return;

    _titleController.text = memory.title;
    _descriptionController.text = memory.description ?? '';
    _selectedDate = memory.happenedAt;
    _currentLocation = memory.location != null
        ? LatLng(memory.location!.latitude, memory.location!.longitude)
        : _defaultLocation;
    _dateController.text =
        '${memory.happenedAt.day.toString().padLeft(2, '0')}/'
        '${memory.happenedAt.month.toString().padLeft(2, '0')}/'
        '${memory.happenedAt.year}';
    _isInitialized = true;
  }

  Future<DateTime?> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
    return picked;
  }

  Future<void> _commitPendingMediaChanges({required String memoryId}) async {
    if (!_mediaEditorController.hasPendingDrafts) return;
    setState(() => _committingMedia = true);
    try {
      await _mediaEditorController.commitPendingChanges(memoryId: memoryId);
    } finally {
      if (mounted) setState(() => _committingMedia = false);
    }
  }

  Future<void> _handleUpsert(Memory? originalMemory) async {
    if (!_formKey.currentState!.validate()) return;

    final memoryController = ref.read(memoryControllerProvider.notifier);

    if (widget.mode == MemoryUpsertMode.create) {
      final newMemory = Memory(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: GeoPoint(
          _currentLocation.latitude,
          _currentLocation.longitude,
        ),
        happenedAt: _selectedDate!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userAsync = ref.read(currentUserProvider);
      if (userAsync is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cargando usuario...'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        return;
      }
      if (userAsync is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el usuario: ${userAsync.error}'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final user = userAsync.value;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      newMemory.participants.add(
        UserRole(user: user, role: MemoryRole.creator),
      );

      try {
        await memoryController.createMemory(newMemory, user.id);
        final createdId = newMemory.id ?? _resolvedMemoryId;
        if (createdId != null) {
          _resolvedMemoryId = createdId;
          await _mediaEditorController.commitPendingChanges(
            memoryId: createdId,
          );
        } else if (_pendingMediaDrafts.isNotEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo obtener el ID para guardar los adjuntos.',
              ),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recuerdo creado correctamente'),
            backgroundColor: AppColors.accentColor,
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear el recuerdo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final updatedMemory = originalMemory!.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      happenedAt: _selectedDate!,
      location: GeoPoint(_currentLocation.latitude, _currentLocation.longitude),
      updatedAt: DateTime.now(),
    );

    try {
      await memoryController.updateMemory(updatedMemory);
      await _commitPendingMediaChanges(memoryId: widget.memoryId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recuerdo actualizado correctamente'),
          backgroundColor: AppColors.accentColor,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el recuerdo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final memoryController = ref.read(memoryControllerProvider.notifier);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este recuerdo? Esta acción es irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await memoryController.deleteMemory(widget.memoryId!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recuerdo eliminado correctamente'),
            backgroundColor: AppColors.accentColor,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el recuerdo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  Future<void> _deleteMediaAsset(MemoryMedia asset) async {
    setState(() => _deletingMediaIds.add(asset.id));
    try {
      final client = Supabase.instance.client;

      if ((asset.storagePath ?? '').isNotEmpty) {
        await client.storage.from('media').remove([asset.storagePath!]);
      }

      await client.from('media').delete().eq('id', asset.id);

      ref.invalidate(memoryMediaProvider(widget.memoryId!));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Archivo eliminado')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $error')));
    } finally {
      if (mounted) {
        setState(() => _deletingMediaIds.remove(asset.id));
      }
    }
  }

  String _mediaLabel(MemoryMedia asset) {
    switch (asset.kind) {
      case MemoryMediaKind.image:
        return 'Imagen';
      case MemoryMediaKind.video:
        return 'Video';
      case MemoryMediaKind.audio:
        return 'Audio';
      case MemoryMediaKind.note:
        return 'Nota';
      case MemoryMediaKind.unknown:
        return 'Archivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == MemoryUpsertMode.edit) {
      final memoryAsync = ref.watch(_memoryByIdProvider(widget.memoryId!));
      return memoryAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(
            title: const Text('Cargando Recuerdo...'),
            backgroundColor: AppColors.primaryColor,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
            backgroundColor: AppColors.primaryColor,
          ),
          body: Center(child: Text('Error al cargar el recuerdo: $err')),
        ),
        data: (memory) {
          _initializeControllers(memory);
          return _buildScaffold(memory: memory);
        },
      );
    }

    return _buildScaffold();
  }

  Scaffold _buildScaffold({Memory? memory}) {
    final isEdit = widget.mode == MemoryUpsertMode.edit;
    final memoryControllerState = ref.watch(memoryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Editar recuerdo' : 'Crear nuevo recuerdo'),
        backgroundColor: AppColors.primaryColor,
        actions: isEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Eliminar recuerdo',
                  onPressed: _handleDelete,
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MemoryForm(
                titleController: _titleController,
                descriptionController: _descriptionController,
                dateController: _dateController,
                readOnly: false,
                onPickDate: _pickDate,
                titleValidator: (value) => (value == null || value.isEmpty)
                    ? 'Ingresa un título'
                    : null,
                dateValidator: (_) => _selectedDate == null
                    ? 'Selecciona la fecha del recuerdo'
                    : null,
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              Text(
                'Ubicación del recuerdo',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 17,
                    minZoom: 2.0,
                    maxZoom: 18.0,
                    onLongPress: (tapPosition, latLng) {
                      setState(() => _currentLocation = latLng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://api.maptiler.com/maps/dataviz/{z}/{x}/{y}.png?key=${EnvConstants.mapTilesApiKey}',
                      userAgentPackageName: 'com.mydearmap.app',
                      tileProvider: kIsWeb ? NetworkTileProvider() : null,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mantén pulsado sobre el mapa para cambiar la ubicación.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              if (isEdit) ...[
                const SizedBox(height: AppSizes.paddingLarge),
                Text(
                  'Archivos adjuntos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Consumer(
                  builder: (context, ref, _) {
                    final mediaAsync = ref.watch(
                      memoryMediaProvider(widget.memoryId!),
                    );
                    return mediaAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(
                          top: AppSizes.paddingMedium,
                          bottom: AppSizes.paddingLarge,
                        ),
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.only(
                          top: AppSizes.paddingMedium,
                          bottom: AppSizes.paddingLarge,
                        ),
                        child: Text(
                          'No se pudo cargar la galería: $error',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (assets) {
                        if (assets.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(
                              top: AppSizes.paddingSmall,
                              bottom: AppSizes.paddingLarge,
                            ),
                            child: Text(
                              'Todavía no hay archivos adjuntos.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            MemoryMediaCarousel(
                              media: assets,
                              height: 180,
                              prioritizeImages: true,
                              enableFullScreenPreview: true,
                            ),
                            const SizedBox(height: AppSizes.paddingMedium),
                            ...assets.map(_buildMediaTile),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSizes.paddingLarge),
              ],
              if (_pendingMediaDrafts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSizes.paddingMedium,
                  ),
                  child: Text(
                    'Se subirán ${_pendingMediaDrafts.length} archivo(s) cuando guardes.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              MemoryMediaEditor(
                memoryId: widget.mode == MemoryUpsertMode.edit
                    ? widget.memoryId!
                    : (_resolvedMemoryId ?? ''),
                controller: _mediaEditorController,
                deferUploads: true,
                onPendingDraftsChanged: (drafts) {
                  if (!mounted) return;
                  setState(() => _pendingMediaDrafts = drafts);
                },
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              AppFormButtons(
                primaryLabel: isEdit ? 'Guardar cambios' : 'Guardar recuerdo',
                onPrimaryPressed: () => _handleUpsert(memory),
                secondaryLabel: 'Cancelar',
                onSecondaryPressed: _handleCancel,
                isProcessing:
                    memoryControllerState.isLoading ||
                    (isEdit ? _committingMedia : false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaTile(MemoryMedia asset) {
    final deleting = _deletingMediaIds.contains(asset.id);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: InkWell(
        onTap: () => _openAssetPreview(asset),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Row(
            children: [
              _MediaThumbnail(asset: asset),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mediaLabel(asset),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _mediaDescription(asset),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              deleting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: 'Eliminar archivo',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _deleteMediaAsset(asset),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAssetPreview(MemoryMedia asset) {
    if (!mounted) return;

    switch (asset.kind) {
      case MemoryMediaKind.image:
        if (asset.publicUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay vista previa disponible.')),
          );
          return;
        }
        showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            insetPadding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: InteractiveViewer(
              child: Image.network(asset.publicUrl!, fit: BoxFit.contain),
            ),
          ),
        );
        break;
      case MemoryMediaKind.note:
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nota'),
            content: Text(
              asset.content?.trim().isNotEmpty == true
                  ? asset.content!.trim()
                  : 'Nota sin contenido.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay vista previa, copia el enlace desde la galería.',
            ),
          ),
        );
    }
  }

  String _mediaDescription(MemoryMedia asset) {
    switch (asset.kind) {
      case MemoryMediaKind.image:
        return 'Toca para ver en grande';
      case MemoryMediaKind.video:
        return 'Toca para abrir o copiar el enlace desde la galería';
      case MemoryMediaKind.audio:
        return 'Audio adjunto';
      case MemoryMediaKind.note:
        return asset.content?.trim().isNotEmpty == true
            ? asset.content!.trim()
            : 'Nota sin contenido.';
      case MemoryMediaKind.unknown:
        return 'Contenido adjunto';
    }
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.asset});

  final MemoryMedia asset;

  @override
  Widget build(BuildContext context) {
    Widget thumbnail;

    switch (asset.kind) {
      case MemoryMediaKind.image:
        thumbnail = Image.network(
          asset.publicUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported, color: Colors.redAccent),
        );
        break;
      case MemoryMediaKind.video:
        thumbnail = const Icon(
          Icons.videocam,
          color: Colors.blueAccent,
          size: 56,
        );
        break;
      case MemoryMediaKind.audio:
        thumbnail = const Icon(
          Icons.audiotrack,
          color: Colors.greenAccent,
          size: 56,
        );
        break;
      case MemoryMediaKind.note:
        thumbnail = Container(
          color: Colors.yellow.shade100,
          child: const Icon(
            Icons.sticky_note_2_outlined,
            color: Colors.orange,
            size: 56,
          ),
        );
        break;
      case MemoryMediaKind.unknown:
        thumbnail = const Icon(
          Icons.insert_drive_file,
          color: Colors.grey,
          size: 56,
        );
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      child: SizedBox(width: 56, height: 56, child: thumbnail),
    );
  }
}

class MemoryDetailEditView extends StatelessWidget {
  const MemoryDetailEditView({super.key, required this.memoryId});

  final String memoryId;

  @override
  Widget build(BuildContext context) {
    return MemoryUpsertView.edit(memoryId: memoryId);
  }
}
