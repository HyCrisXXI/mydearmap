// lib/features/memories/views/memory_form_view.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/memories/controllers/memory_controller.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/features/memories/widgets/memory_media_editor.dart'
    show
        MemoryMediaEditor,
        MemoryMediaEditorController,
        PendingMemoryMediaDraft;

import 'package:mydearmap/features/memories/widgets/memory_form_carrousel.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/map/views/map_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mydearmap/features/memories/widgets/media_action_buttons.dart';

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
  int _currentStep = 0;
  static const List<String> _stepLabels = [
    'Fecha y ubicación',
    'Multimedia',
    'Detalles finales',
  ];
  DateTime? _selectedDate;
  LatLng _currentLocation = _defaultLocation;
  final Set<String> _deletingMediaIds = <String>{};

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _mapController = MapController();

  // selected related users (userId -> roleName)
  final Map<String, String> _selectedRelationUserRoles = <String, String>{};

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
    _dateController.text = _formatDate(memory.happenedAt);
    // Initializar personas relacionadas desde los participantes del recuerdo (excluir creador)
    _relatedPeople = memory.participants
        .where((p) => p.role != MemoryRole.creator)
        .toList();
    _selectedRelationUserRoles
      ..clear()
      ..addEntries(
        _relatedPeople
            .where((p) => p.user.id.isNotEmpty)
            .map((p) => MapEntry<String, String>(p.user.id, p.role.name)),
      );

    _isInitialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  MemoryRole _roleFromName(String? raw) {
    if (raw == null) return MemoryRole.participant;
    return MemoryRole.values.firstWhere(
      (role) => role.name == raw,
      orElse: () => MemoryRole.participant,
    );
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
      _updateSelectedDate(picked);
    }
    return picked;
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dateController.text = _formatDate(date);
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  void _handleManualDateInput(String raw) {
    FocusScope.of(context).unfocus();
    final sanitized = raw.trim();
    if (sanitized.isEmpty) {
      setState(() => _selectedDate = null);
      return;
    }
    final parts = sanitized.split(RegExp(r'[-/\s]+'));
    if (parts.length != 3) {
      _showDateError();
      return;
    }
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      _showDateError();
      return;
    }
    final parsed = DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}',
    );
    if (parsed == null || parsed.isAfter(DateTime.now())) {
      _showDateError();
      return;
    }
    _updateSelectedDate(parsed);
  }

  void _showDateError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formato de fecha inválido (dd/mm/aaaa).')),
    );
    if (_selectedDate != null) {
      _dateController.text = _formatDate(_selectedDate!);
    } else {
      _dateController.clear();
    }
  }

  void _handlePrimaryAction(Memory? memory) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    if (_currentStep == 0) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona la fecha del recuerdo')),
        );
        return;
      }
      setState(() => _currentStep = 1);
      return;
    }
    if (_currentStep == 1) {
      setState(() => _currentStep = 2);
      return;
    }
    _confirmAndSave(memory);
  }

  Future<void> _confirmAndSave(Memory? memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.mode == MemoryUpsertMode.create
              ? 'Crear recuerdo'
              : 'Guardar cambios',
        ),
        content: Text(
          widget.mode == MemoryUpsertMode.create
              ? '¿Estás seguro de que deseas crear este recuerdo?'
              : '¿Estás seguro de que deseas guardar los cambios?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              widget.mode == MemoryUpsertMode.create ? 'Crear' : 'Guardar',
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _handleUpsert(memory);
    }
  }

  void _handleSecondaryAction() {
    if (_currentStep == 0) {
      _handleCancel();
      return;
    }
    setState(() => _currentStep -= 1);
  }

  void _onPendingDraftsChanged(List<PendingMemoryMediaDraft> drafts) {
    if (mounted) {
      setState(() => _pendingMediaDrafts = drafts);
    }
  }

  String _roleDisplayName(MemoryRole role) {
    switch (role) {
      case MemoryRole.creator:
        return 'Creador';
      case MemoryRole.participant:
        return 'Participante';
      case MemoryRole.guest:
        return 'Invitado';
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
    final isProcessing =
        memoryControllerState.isLoading || _committingMedia || _reorderingMedia;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight:
            AppSizes.appBarHeight, // Separacion respecto al borde superior
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSizes.paddingMedium),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: SvgPicture.asset(AppIcons.chevronLeft),
                onPressed: _handleSecondaryAction,
                style: AppButtonStyles.circularIconButton,
              ),
              if (isEdit) ...[
                const SizedBox(width: 16),
                IconButton(
                  icon: SvgPicture.asset(AppIcons.trash),
                  tooltip: 'Eliminar recuerdo',
                  onPressed: _handleDelete,
                  style: AppButtonStyles.circularIconButton,
                ),
              ],
            ],
          ),
        ),
        leadingWidth: isEdit
            ? 140
            : 70, // Adjust width for 2 buttons if editing
        title: null, // Removed title
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.paddingMedium),
            child: _currentStep < 2
                ? FilledButton(
                    onPressed: isProcessing
                        ? null
                        : () => _handlePrimaryAction(memory),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.buttonForeground,
                      foregroundColor: AppColors.buttonBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadius,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.buttonPaddingHorizontal,
                      ),
                    ),
                    child: const Text(
                      'Siguiente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.textButton,
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: isProcessing
                        ? null
                        : () => _handlePrimaryAction(memory),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      foregroundColor: AppColors.buttonForeground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadius,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.buttonPaddingHorizontal,
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.buttonForeground,
                            ),
                          )
                        : Text(
                            isEdit ? 'Guardar' : 'Crear',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: AppSizes.paddingLarge),
              _buildStepContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Center(
      child: Text(
        _stepLabels[_currentStep],
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStepContent() {
    final steps = [
      _buildSchedulingStep(),
      _buildMediaStep(),
      _buildDetailsStep(),
    ];

    return Stack(
      children: List.generate(steps.length, (index) {
        final visible = _currentStep == index;
        return Offstage(
          key: ValueKey('step_$index'),
          offstage: !visible,
          child: TickerMode(enabled: visible, child: steps[index]),
        );
      }),
    );
  }

  Widget _buildSchedulingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elige cuándo y dónde sucedió el recuerdo',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        AspectRatio(
          aspectRatio: 1.0,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              child: CalendarDatePicker(
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                onDateChanged: _updateSelectedDate,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        TextFormField(
          controller: _dateController,
          keyboardType: TextInputType.datetime,
          decoration: InputDecoration(
            labelText: 'Fecha (dd/mm/aaaa)',
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate,
            ),
          ),
          onEditingComplete: () => _handleManualDateInput(_dateController.text),
          onFieldSubmitted: _handleManualDateInput,
        ),
        const SizedBox(height: AppSizes.paddingLarge),
        Text(
          'Ubicación del recuerdo',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: FlutterMap(
              key: ValueKey(
                '${_currentLocation.latitude}_${_currentLocation.longitude}',
              ),
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 17,
                minZoom: 2.0,
                maxZoom: 18.0,
                onLongPress: (_, latLng) {
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
        ),
        const SizedBox(height: 16),
        Text(
          'Mantén pulsado sobre el mapa para cambiar la ubicación.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMediaStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona fotos, vídeos o audios para tu recuerdo',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        MemoryMediaEditor(
          memoryId: widget.mode == MemoryUpsertMode.edit
              ? widget.memoryId!
              : (_resolvedMemoryId ?? ''),
          controller: _mediaEditorController,
          deferUploads: true,
          onPendingDraftsChanged: _onPendingDraftsChanged,
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        const SizedBox(height: AppSizes.paddingSmall),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final mediaAsync =
        widget.mode == MemoryUpsertMode.edit && widget.memoryId != null
        ? ref.watch(memoryMediaProvider(widget.memoryId!))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMediaSummarySection(mediaAsync),
        const SizedBox(height: AppSizes.paddingLarge),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Título'),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Ingresa un título'
              : null,
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        TextFormField(
          controller: _descriptionController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        _buildRelationsSelector(),
        const SizedBox(height: AppSizes.paddingSmall),
        _buildSelectedRelationsList(),
        const SizedBox(height: AppSizes.paddingLarge),
        _buildReorderSection(mediaAsync),
      ],
    );
  }

  Widget _buildMediaSummarySection(AsyncValue<List<MemoryMedia>>? mediaAsync) {
    if (mediaAsync == null) {
      if (_pendingMediaDrafts.isEmpty) {
        return const SizedBox(
          height: 100,
          child: Center(
            child: Text(
              'Añade adjuntos en el paso anterior para verlos aquí.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      }
      // Show pending drafts as carousel
      final mergedAssets = <MemoryMedia>[];
      for (final draft in _pendingMediaDrafts) {
        mergedAssets.add(
          MemoryMedia(
            id: 'draft_${draft.hashCode}',
            kind: draft.kind,
            createdAt: DateTime.now(),
            order: null,
            previewBytes: draft.previewBytes,
            publicUrl: null,
          ),
        );
      }
      return SizedBox(
        height: AppCardMemory.previewHeight,
        child: MemoryFormCarrousel(media: mergedAssets),
      );
    }

    return mediaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (error, _) => Text(
        'No se pudo cargar la galería: $error',
        style: const TextStyle(color: Colors.redAccent),
      ),
      data: (assets) {
        final mergedAssets = <MemoryMedia>[...assets];

        for (final draft in _pendingMediaDrafts) {
          mergedAssets.add(
            MemoryMedia(
              id: 'draft_${draft.hashCode}',
              kind: draft.kind,
              createdAt: DateTime.now(),
              order: null,
              previewBytes: draft.previewBytes,
              publicUrl: null,
            ),
          );
        }

        if (mergedAssets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: AppSizes.paddingSmall),
            child: Text(
              'Todavía no hay archivos adjuntos guardados.',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return SizedBox(
          height: AppCardMemory.previewHeight,
          child: MemoryFormCarrousel(media: mergedAssets),
        );
      },
    );
  }

  Widget _buildSelectedRelationsList() {
    if (_relatedPeople.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _relatedPeople.map((person) {
        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
          child: ListTile(
            dense: true,
            title: Text(
              person.user.name.isNotEmpty
                  ? person.user.name
                  : person.user.email,
            ),
            subtitle: Text(_roleDisplayName(person.role)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<MemoryRole>(
                  value: person.role,
                  items: const [
                    DropdownMenuItem(
                      value: MemoryRole.participant,
                      child: Text('Participante'),
                    ),
                    DropdownMenuItem(
                      value: MemoryRole.guest,
                      child: Text('Invitado'),
                    ),
                  ],
                  onChanged: (role) {
                    if (role == null) return;
                    setState(() {
                      final idx = _relatedPeople.indexWhere(
                        (element) => element.user.id == person.user.id,
                      );
                      if (idx != -1) {
                        _relatedPeople[idx] = UserRole(
                          user: person.user,
                          role: role,
                        );
                      }
                      _selectedRelationUserRoles[person.user.id] = role.name;
                    });
                  },
                ),
                IconButton(
                  tooltip: 'Quitar persona',
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _relatedPeople.removeWhere(
                        (p) => p.user.id == person.user.id,
                      );
                      _selectedRelationUserRoles.remove(person.user.id);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRelationsSelector() {
    final currentUserAsync = ref.watch(currentUserProvider);
    return currentUserAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final relationsAsync = ref.watch(userRelationsProvider(user.id));
        return relationsAsync.when(
          data: (relations) {
            if (relations.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Personas relacionadas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final temp = Map<String, String>.from(
                      _selectedRelationUserRoles,
                    );
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) {
                        return AlertDialog(
                          title: const Text(
                            'Seleccionar personas relacionadas',
                          ),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return relations.isEmpty
                                    ? const Text(
                                        'No hay relaciones disponibles',
                                      )
                                    : ListView(
                                        shrinkWrap: true,
                                        children: relations.map((r) {
                                          final related = r.relatedUser;
                                          final id = related.id;
                                          final selected = temp.containsKey(id);
                                          return ListTile(
                                            leading: Checkbox(
                                              value: selected,
                                              onChanged: (v) {
                                                setStateDialog(() {
                                                  if (v == true) {
                                                    temp[id] = MemoryRole
                                                        .participant
                                                        .name;
                                                  } else {
                                                    temp.remove(id);
                                                  }
                                                });
                                              },
                                            ),
                                            title: Text(
                                              related.name.isNotEmpty
                                                  ? related.name
                                                  : related.email,
                                            ),
                                            trailing: selected
                                                ? DropdownButton<String>(
                                                    value: temp[id],
                                                    items: [
                                                      DropdownMenuItem(
                                                        value: MemoryRole
                                                            .participant
                                                            .name,
                                                        child: const Text(
                                                          'Participante',
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: MemoryRole
                                                            .guest
                                                            .name,
                                                        child: const Text(
                                                          'Invitado',
                                                        ),
                                                      ),
                                                    ],
                                                    onChanged: (val) {
                                                      if (val == null) return;
                                                      setStateDialog(() {
                                                        temp[id] = val;
                                                      });
                                                    },
                                                  )
                                                : null,
                                          );
                                        }).toList(),
                                      );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedRelationUserRoles
                                    ..clear()
                                    ..addAll(temp);
                                  // Sync _relatedPeople from selections
                                  final relationUsers = <String, User>{
                                    for (final rel in relations)
                                      rel.relatedUser.id: rel.relatedUser,
                                  };
                                  final existingUsers = <String, User>{
                                    for (final person in _relatedPeople)
                                      person.user.id: person.user,
                                  };
                                  final synced = _selectedRelationUserRoles
                                      .entries
                                      .map((entry) {
                                        final user =
                                            relationUsers[entry.key] ??
                                            existingUsers[entry.key];
                                        if (user == null) return null;
                                        return UserRole(
                                          user: user,
                                          role: _roleFromName(entry.value),
                                        );
                                      })
                                      .whereType<UserRole>()
                                      .toList();
                                  _relatedPeople = synced;
                                });
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: _selectedRelationUserRoles.isEmpty
                        ? const Text('Ninguna seleccionada')
                        : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: relations
                                .where(
                                  (r) => _selectedRelationUserRoles.containsKey(
                                    r.relatedUser.id,
                                  ),
                                )
                                .map((r) {
                                  final role =
                                      _selectedRelationUserRoles[r
                                          .relatedUser
                                          .id];
                                  return Chip(
                                    label: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.relatedUser.name.isNotEmpty
                                              ? r.relatedUser.name
                                              : r.relatedUser.email,
                                        ),
                                        if (role != null)
                                          Text(
                                            role,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                  ),
                ),
              ],
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: const Text('Error cargando relaciones'),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildReorderSection(AsyncValue<List<MemoryMedia>>? mediaAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organiza los adjuntos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        if (_reorderingMedia)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSizes.paddingSmall),
            child: LinearProgressIndicator(),
          ),

        if (mediaAsync != null)
          mediaAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSizes.paddingMedium),
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.only(top: AppSizes.paddingMedium),
              child: Text(
                'No se pudo cargar la galería: $error',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            data: (assets) {
              if (assets.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: AppSizes.paddingSmall),
                  child: Text(
                    'No hay archivos guardados para organizar.',
                    style: TextStyle(color: Colors.black54),
                  ),
                );
              }
              final orderedAssets = List<MemoryMedia>.from(assets);
              return Column(
                children: List.generate(
                  orderedAssets.length,
                  (index) => _buildMediaTile(orderedAssets, index),
                ),
              );
            },
          ),
      ],
    );
  }

  // Fix: restore upsert handler from original view (create/edit logic)
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
        final createdId =
            createdMemory?.id ?? newMemory.id ?? _resolvedMemoryId;
        if (createdId != null) {
          _resolvedMemoryId = createdId;

          final toUpsert = _relatedPeople
              .where((ur) => ur.user.id.isNotEmpty && ur.user.id != user.id)
              .toList();
          if (toUpsert.isNotEmpty) {
            final List<String> failed = [];
            for (final ur in toUpsert) {
              try {
                await memoryController.addParticipant(
                  createdId,
                  ur.user.id,
                  ur.role.name,
                );
              } catch (_) {
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

          await _mediaEditorController.commitPendingChanges(
            memoryId: createdId,
          );

          for (final relatedUserId in _selectedRelationUserRoles.keys) {
            if (relatedUserId == user.id) continue;
            final roleName =
                _selectedRelationUserRoles[relatedUserId] ??
                MemoryRole.participant.name;
            await memoryController.addParticipant(
              createdId,
              relatedUserId,
              roleName,
            );
          }
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

    // Edit flow
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
      if (mounted) setState(() => _locationDirty = false);

      // Sync participants: add newly selected, remove deselected
      final existingIds = originalMemory.participants
          .map((p) => p.user.id)
          .toSet();
      final currentSelectedIds = _selectedRelationUserRoles.keys.toSet();
      final toAdd = currentSelectedIds.difference(existingIds);
      final toRemove = existingIds.difference(currentSelectedIds);

      for (final id in toAdd) {
        if (id == ref.read(currentUserProvider).asData?.value?.id) continue;
        final roleName =
            _selectedRelationUserRoles[id] ?? MemoryRole.participant.name;
        await memoryController.addParticipant(widget.memoryId!, id, roleName);
      }
      for (final id in toRemove) {
        final matches = originalMemory.participants
            .where((p) => p.user.id == id)
            .toList();
        if (matches.isEmpty) continue;
        final participant = matches.first;
        if (participant.role == MemoryRole.creator) continue;
        await memoryController.removeParticipant(widget.memoryId!, id);
      }

      // Sync role changes
      try {
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
        final addIds = current.keys.where((k) => !orig.containsKey(k));
        final removeIds = orig.keys.where((k) => !current.containsKey(k));
        final maybeUpdateIds = current.keys.where((k) => orig.containsKey(k));
        for (final id in addIds) {
          await memoryController.addParticipant(
            widget.memoryId!,
            id,
            current[id]!.name,
          );
        }
        for (final id in removeIds) {
          await memoryController.removeParticipant(widget.memoryId!, id);
        }
        for (final id in maybeUpdateIds) {
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
      } catch (_) {}

      if (widget.memoryId != null) {
        ref.invalidate(_memoryByIdProvider(widget.memoryId!));
      }
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

  Future<void> _commitPendingMediaChanges({required String memoryId}) async {
    if (!_mediaEditorController.hasPendingDrafts) return;
    setState(() => _committingMedia = true);
    try {
      await _mediaEditorController.commitPendingChanges(memoryId: memoryId);
    } finally {
      if (mounted) setState(() => _committingMedia = false);
    }
  }

  void _handleCancel() => Navigator.of(context).pop();

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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapView()),
        );
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
      case MemoryMediaKind.unknown:
      default:
        return 'Archivo';
    }
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
    final canMoveUp = index > 0;
    final canMoveDown = index < assets.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _openAssetPreview(asset),
              child: _MediaThumbnail(asset: asset),
            ),
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
            MediaActionButtons(
              onMoveUp: _reorderingMedia
                  ? null
                  : () => _reorderMediaAsset(assets, index, index - 1),
              showMoveUp: canMoveUp,
              onMoveDown: _reorderingMedia
                  ? null
                  : () => _reorderMediaAsset(assets, index, index + 1),
              showMoveDown: canMoveDown,
              onDelete: () => _deleteMediaAsset(asset),
              isDeleting: deleting,
            ),
          ],
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

    final reordered = List<MemoryMedia>.from(assets);
    final movedItem = reordered.removeAt(fromIndex);
    reordered.insert(toIndex, movedItem);

    setState(() => _reorderingMedia = true);

    try {
      final client = Supabase.instance.client;
      // Update order for all items to ensure consistency
      for (var i = 0; i < reordered.length; i++) {
        final asset = reordered[i];
        final newOrder = i;
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

  void _openAssetPreview(MemoryMedia asset) {
    if (!mounted) return;

    switch (asset.kind) {
      case MemoryMediaKind.image:
        if (asset.publicUrl == null && asset.previewBytes == null) {
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
              child: asset.previewBytes != null
                  ? Image.memory(asset.previewBytes!, fit: BoxFit.contain)
                  : Image.network(asset.publicUrl!, fit: BoxFit.contain),
            ),
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
      case MemoryMediaKind.unknown:
      default:
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
        if (asset.previewBytes != null) {
          thumbnail = Image.memory(asset.previewBytes!, fit: BoxFit.cover);
        } else if (asset.publicUrl != null) {
          final url = asset.publicUrl!;
          if (url.startsWith('file://')) {
            thumbnail = Image.file(
              File(Uri.parse(url).toFilePath()),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.redAccent),
            );
          } else {
            thumbnail = Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                color: Colors.redAccent,
              ),
            );
          }
        } else {
          thumbnail = const Icon(Icons.image, color: Colors.grey);
        }
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
      case MemoryMediaKind.unknown:
      default:
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
