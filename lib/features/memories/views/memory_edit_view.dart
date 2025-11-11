// lib/features/memories/views/memory_edit_view.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/widgets/app_form_buttons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/memories/controllers/memory_controller.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/features/memories/widgets/memory_form.dart';
import 'package:mydearmap/features/memories/widgets/memory_media_editor.dart'
    show
        MemoryMediaEditor,
        MemoryMediaEditorController,
        PendingMemoryMediaDraft;
import 'package:mydearmap/features/memories/widgets/memory_media_carousel.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';

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
  List<UserRole> _relatedPeople = [];
  bool _committingMedia = false;
  bool _reorderingMedia = false;
  bool _isInitialized = false;
  bool _locationDirty = false;
  String? _resolvedMemoryId;

  @override
  void initState() {
    super.initState();
    if (widget.mode == MemoryUpsertMode.create) {
      _currentLocation = widget.initialLocation ?? _defaultLocation;
      _isInitialized = true;
      _locationDirty = true;
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
    _locationDirty = false;
    _dateController.text =
        '${memory.happenedAt.day.toString().padLeft(2, '0')}/'
        '${memory.happenedAt.month.toString().padLeft(2, '0')}/'
        '${memory.happenedAt.year}';
    // Initialize related people from memory participants (exclude creator)
    _relatedPeople = memory.participants
        .where((p) => p.role != MemoryRole.creator)
        .toList();
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

      // participants will be synchronized separately via memory_users table

      final userAsync = ref.read(currentUserProvider);
      if (userAsync is AsyncLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cargando usuario...')));
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
        final createdMemory = await memoryController.createMemory(
          newMemory,
          user.id,
        );
        final createdId = createdMemory.id ?? _resolvedMemoryId;
        // Add related participants (skip creator). Validate IDs and capture failures.
        if (createdId != null) {
          _resolvedMemoryId = createdId;
          final toUpsert = _relatedPeople
              .where((ur) => ur.user.id.isNotEmpty && ur.user.id != user.id)
              .toList();

          if (toUpsert.isNotEmpty) {
            // Log what we'll attempt to upsert
            try {
              print(
                'Will upsert participants for memory $createdId: ${toUpsert.map((u) => u.user.id).toList()}',
              );
            } catch (_) {}

            final List<String> failed = [];
            for (final ur in toUpsert) {
              try {
                await memoryController.addParticipant(
                  createdId,
                  ur.user.id,
                  ur.role.name,
                );
              } catch (e) {
                try {
                  print('Failed adding participant ${ur.user.id} -> $e');
                } catch (_) {}
                failed.add(ur.user.id);
              }
            }

            if (failed.isNotEmpty && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'No se pudieron añadir ${failed.length} participantes.',
                  ),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            }
          }

          // Commit pending media after participants upsert
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
        if (createdId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MemoryDetailView(memoryId: createdId),
            ),
          );
        } else {
          Navigator.of(context).pop(true);
        }
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
      location: _resolveUpdatedLocation(originalMemory),
      updatedAt: DateTime.now(),
    );

    try {
      await memoryController.updateMemory(updatedMemory);
      await _commitPendingMediaChanges(memoryId: widget.memoryId!);
      if (mounted) {
        setState(() => _locationDirty = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recuerdo actualizado correctamente'),
          backgroundColor: AppColors.accentColor,
        ),
      );
      // Sync participants: compute added, removed, changed roles
      try {
        // Fetch participants from server to get the most up-to-date 'orig' state
        List<UserRole> serverParticipants = [];
        try {
          final serverMemory = await memoryController.getMemoryById(
            widget.memoryId!,
          );
          serverParticipants =
              serverMemory?.participants ?? originalMemory.participants;
        } catch (_) {
          serverParticipants = originalMemory.participants;
        }

        final orig = <String, MemoryRole>{};
        for (final p in serverParticipants) {
          if (p.role == MemoryRole.creator) continue;
          orig[p.user.id] = p.role;
        }

        final current = <String, MemoryRole>{};
        for (final p in _relatedPeople) {
          if (p.user.id.isEmpty) continue;
          current[p.user.id] = p.role;
        }

        final toAdd = current.keys.where((k) => !orig.containsKey(k));
        final toRemove = orig.keys.where((k) => !current.containsKey(k));
        final toMaybeUpdate = current.keys.where((k) => orig.containsKey(k));

        for (final id in toAdd) {
          final role = current[id]!;
          await memoryController.addParticipant(
            widget.memoryId!,
            id,
            role.name,
          );
        }

        for (final id in toRemove) {
          await memoryController.removeParticipant(widget.memoryId!, id);
        }

        for (final id in toMaybeUpdate) {
          final newRole = current[id]!;
          final oldRole = orig[id]!;
          if (newRole != oldRole) {
            await memoryController.addParticipant(
              widget.memoryId!,
              id,
              newRole.name,
            );
          }
        }
      } catch (e) {
        try {
          print('Error syncing participants on update: $e');
        } catch (_) {}
      }

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
      ref.invalidate(userMemoriesProvider);

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

  String _mediaLabel(MemoryMedia asset) => _kindLabel(asset.kind);

  String _kindLabel(MemoryMediaKind kind) {
    switch (kind) {
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
    final currentUserAsync = ref.watch(currentUserProvider);
    final List<User> availableUsers = currentUserAsync.maybeWhen(
      data: (user) {
        if (user == null) return <User>[];
        final relationsAsync = ref.watch(userRelationsProvider(user.id));
        return relationsAsync.maybeWhen(
          data: (rels) => rels.map((r) => r.relatedUser).toList(),
          orElse: () => <User>[],
        );
      },
      orElse: () => <User>[],
    );

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
                relatedPeople: _relatedPeople,
                availableUsers: availableUsers,
                onAddUser: (p) => setState(() => _relatedPeople.add(p)),
                onRemoveUser: (p) => setState(() {
                  _relatedPeople.removeWhere((x) => x.user.id == p.user.id);
                }),
                onChangeRole: (p) => setState(() {
                  final idx = _relatedPeople.indexWhere(
                    (x) => x.user.id == p.user.id,
                  );
                  if (idx != -1) _relatedPeople[idx] = p;
                }),
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
                      setState(() {
                        _currentLocation = latLng;
                        _locationDirty = true;
                      });
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

                        final orderedAssets = List<MemoryMedia>.from(assets);

                        return Column(
                          children: [
                            MemoryMediaCarousel(
                              media: orderedAssets,
                              height: 180,
                              prioritizeImages: true,
                              enableFullScreenPreview: true,
                            ),
                            const SizedBox(height: AppSizes.paddingMedium),
                            if (_reorderingMedia)
                              const Padding(
                                padding: EdgeInsets.only(
                                  bottom: AppSizes.paddingMedium,
                                ),
                                child: LinearProgressIndicator(),
                              ),
                            ...List.generate(
                              orderedAssets.length,
                              (index) => _buildMediaTile(orderedAssets, index),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSizes.paddingLarge),
              ],
              if (_pendingMediaDrafts.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjuntos pendientes (${_pendingMediaDrafts.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      'Los archivos se subirán al guardar. Ajusta el orden antes de continuar.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    ...List.generate(
                      _pendingMediaDrafts.length,
                      _buildPendingDraftTile,
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                  ],
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
                    (isEdit ? (_committingMedia || _reorderingMedia) : false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  GeoPoint _resolveUpdatedLocation(Memory original) {
    if (!_locationDirty && original.location != null) {
      return original.location!;
    }
    return GeoPoint(_currentLocation.latitude, _currentLocation.longitude);
  }

  Widget _buildMediaTile(List<MemoryMedia> assets, int index) {
    final asset = assets[index];
    final deleting = _deletingMediaIds.contains(asset.id);
    final isFirst = index == 0;
    final isLast = index == assets.length - 1;
    final canMoveUp = !isFirst && assets[index - 1].kind == asset.kind;
    final canMoveDown = !isLast && assets[index + 1].kind == asset.kind;
    final relativeOrder = _indexWithinKind(assets, asset);

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
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSizes.paddingSmall,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          label: Text(
                            'Orden ${relativeOrder >= 0 ? relativeOrder : '?'}',
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          _kindPriorityLabel(asset.kind),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Mover arriba',
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: (!_reorderingMedia && canMoveUp)
                        ? () => _reorderMediaAsset(assets, index, index - 1)
                        : null,
                  ),
                  IconButton(
                    tooltip: 'Mover abajo',
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: (!_reorderingMedia && canMoveDown)
                        ? () => _reorderMediaAsset(assets, index, index + 1)
                        : null,
                  ),
                  deleting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reorderMediaAsset(
    List<MemoryMedia> assets,
    int fromIndex,
    int toIndex,
  ) async {
    if (widget.memoryId == null) return;
    if (fromIndex == toIndex) return;
    if (toIndex < 0 || toIndex >= assets.length) return;
    final source = assets[fromIndex];
    final target = assets[toIndex];
    if (source.kind != target.kind) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solo puedes cambiar el orden dentro del mismo tipo.',
            ),
          ),
        );
      }
      return;
    }

    final sameTypeAssets = assets
        .where((asset) => asset.kind == source.kind)
        .toList();
    final fromTypeIndex = sameTypeAssets.indexWhere(
      (element) => element.id == source.id,
    );
    final toTypeIndex = sameTypeAssets.indexWhere(
      (element) => element.id == target.id,
    );
    if (fromTypeIndex == -1 || toTypeIndex == -1) return;
    if (fromTypeIndex == toTypeIndex) return;

    final reordered = List<MemoryMedia>.from(sameTypeAssets);
    final moved = reordered.removeAt(fromTypeIndex);
    reordered.insert(toTypeIndex, moved);

    setState(() => _reorderingMedia = true);

    try {
      final client = Supabase.instance.client;
      final base = _orderBaseForKind(source.kind);
      for (var i = 0; i < reordered.length; i++) {
        final asset = reordered[i];
        final newOrder = base + i;
        await client
            .from('media')
            .update({'order': newOrder})
            .eq('id', asset.id);
      }
      ref.invalidate(memoryMediaProvider(widget.memoryId!));
      ref.invalidate(userMemoriesProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar el orden: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _reorderingMedia = false);
      }
    }
  }

  String _kindPriorityLabel(MemoryMediaKind kind) {
    switch (kind) {
      case MemoryMediaKind.image:
        return 'Prioridad: Imagen';
      case MemoryMediaKind.video:
        return 'Prioridad: Video';
      case MemoryMediaKind.audio:
        return 'Prioridad: Audio';
      case MemoryMediaKind.note:
        return 'Prioridad: Nota';
      case MemoryMediaKind.unknown:
        return 'Prioridad: Archivo';
    }
  }

  int _orderBaseForKind(MemoryMediaKind kind) {
    switch (kind) {
      case MemoryMediaKind.image:
        return 0;
      case MemoryMediaKind.video:
        return 100000;
      case MemoryMediaKind.audio:
        return 200000;
      case MemoryMediaKind.note:
        return 300000;
      case MemoryMediaKind.unknown:
        return 400000;
    }
  }

  int _indexWithinKind(List<MemoryMedia> assets, MemoryMedia target) {
    var index = 0;
    for (final item in assets) {
      if (item.kind != target.kind) continue;
      if (item.id == target.id) return index;
      index++;
    }
    return -1;
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

  Widget _buildPendingDraftTile(int index) {
    final draft = _pendingMediaDrafts[index];
    final canMoveUp = index > 0;
    final canMoveDown = index < _pendingMediaDrafts.length - 1;

    Widget preview;
    switch (draft.kind) {
      case MemoryMediaKind.image:
        preview = draft.previewBytes != null
            ? Image.memory(
                draft.previewBytes!,
                fit: BoxFit.cover,
                width: 72,
                height: 72,
              )
            : const Icon(Icons.image, size: 48, color: Colors.blueGrey);
        break;
      case MemoryMediaKind.video:
        preview = const Icon(
          Icons.play_circle_outline,
          size: 48,
          color: Colors.deepPurple,
        );
        break;
      case MemoryMediaKind.audio:
        preview = const Icon(Icons.graphic_eq, size: 48, color: Colors.teal);
        break;
      case MemoryMediaKind.note:
        preview = Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          color: Colors.yellow.shade100,
          child: const Icon(
            Icons.sticky_note_2_outlined,
            size: 40,
            color: Colors.orange,
          ),
        );
        break;
      case MemoryMediaKind.unknown:
        preview = const Icon(
          Icons.insert_drive_file,
          size: 48,
          color: Colors.grey,
        );
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              child: SizedBox(width: 72, height: 72, child: preview),
            ),
            const SizedBox(width: AppSizes.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kindLabel(draft.kind),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (draft.kind == MemoryMediaKind.note &&
                      (draft.noteContent?.isNotEmpty ?? false))
                    Text(
                      draft.noteContent!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    )
                  else
                    Text(
                      draft.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Mover arriba',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: canMoveUp
                      ? () => _mediaEditorController.reorderDraft(
                          index,
                          index - 1,
                        )
                      : null,
                ),
                IconButton(
                  tooltip: 'Mover abajo',
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: canMoveDown
                      ? () => _mediaEditorController.reorderDraft(
                          index,
                          index + 1,
                        )
                      : null,
                ),
                IconButton(
                  tooltip: 'Quitar adjunto',
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () => _mediaEditorController.removeDraftAt(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
