// lib/features/memories/views/memory_detail_edit_view.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import '../../../core/constants/constants.dart';
import '../controllers/memory_controller.dart';
import '../../../data/models/memory.dart';
import '../widgets/memory_form.dart';
import '../widgets/memory_action_buttons.dart';

final _memoryByIdProvider = FutureProvider.family<Memory, String>((ref, memoryId) async {
  final memoryController = ref.read(memoryControllerProvider.notifier);
  final memory = await memoryController.getMemoryById(memoryId);

  if (memory == null) {
    throw Exception('Recuerdo con ID "$memoryId" no encontrado.');
  }
  return memory;
});


const LatLng _defaultLocation = LatLng(39.4699, -0.3763); 

class MemoryDetailEditView extends ConsumerStatefulWidget {
  final String memoryId;

  const MemoryDetailEditView({
    super.key,
    required this.memoryId,
  });

  @override
  ConsumerState<MemoryDetailEditView> createState() => _MemoryDetailEditViewState();
}

class _MemoryDetailEditViewState extends ConsumerState<MemoryDetailEditView> {
  DateTime? _selectedDate;
  LatLng _currentLocation = _defaultLocation; 
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _mapController = MapController();

  bool _isEditing = false;
  bool _isInitialized = false;

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

    if (memory.location != null) {
      _currentLocation = LatLng(memory.location!.latitude, memory.location!.longitude);
    } else {
      _currentLocation = _defaultLocation;
    }

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


  Future<void> _handleUpdate(Memory originalMemory) async {
    final memoryController = ref.read(memoryControllerProvider.notifier);

    if (!_formKey.currentState!.validate()) return;
    

    final updatedMemory = originalMemory.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      happenedAt: _selectedDate!,
      location: GeoPoint(_currentLocation.latitude, _currentLocation.longitude), 
      updatedAt: DateTime.now(),
    );

    try {
      await memoryController.updateMemory(updatedMemory);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recuerdo actualizado correctamente'),
          backgroundColor: AppColors.accentColor,
        ),
      );
      setState(() => _isEditing = false);
      ref.invalidate(_memoryByIdProvider(widget.memoryId));

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
        content: const Text('¿Estás seguro de que deseas eliminar este recuerdo? Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await memoryController.deleteMemory(widget.memoryId);
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

  void _handleCancel(Memory memory) {
    if (_isEditing) {
      _isInitialized = false;
      _initializeControllers(memory);

      setState(() {
        _isEditing = false;
      });
      _mapController.move(_currentLocation, 17);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoryAsyncValue = ref.watch(_memoryByIdProvider(widget.memoryId));
    final memoryControllerState = ref.watch(memoryControllerProvider);

    return memoryAsyncValue.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Cargando Recuerdo...'), backgroundColor: AppColors.primaryColor),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error'), backgroundColor: AppColors.primaryColor),
        body: Center(child: Text('Error al cargar el recuerdo: $err')),
      ),
      data: (memory) {
        _initializeControllers(memory);

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(_isEditing ? 'Editar Recuerdo' : memory.title),
            backgroundColor: AppColors.primaryColor,
            actions: [
              
              if (!_isEditing) ...[
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Eliminar recuerdo',
                  onPressed: _handleDelete, 
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
            ],
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
                    readOnly: !_isEditing,
                    onPickDate: _isEditing ? _pickDate : null,
                    titleValidator: (value) => (_isEditing && (value == null || value.isEmpty))
                        ? 'Ingresa un título' : null,
                    dateValidator: (_) => (_isEditing && _selectedDate == null)
                        ? 'Selecciona la fecha del recuerdo' : null,
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),

                  if (_isEditing)
                    MemoryActionButtons(
                      editing: true,
                      isLoading: memoryControllerState.isLoading,
                      onSave: () => _handleUpdate(memory),
                      onCancel: () => _handleCancel(memory),
                      primaryLabel: 'Guardar cambios',
                      cancelLabel: 'Cancelar',
                    ),

                  const SizedBox(height: 24),

                  Text(
                    'Ubicación del recuerdo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                        onLongPress: _isEditing
                            ? (tapPosition, latLng) {
                                setState(() {
                                  _currentLocation = latLng;
                                });
                              }
                            : null,
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
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Mantén pulsado sobre el mapa para cambiar la ubicación.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}