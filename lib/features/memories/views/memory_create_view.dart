// lib/features/memories/views/memory_create_view.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/widgets/app_form_buttons.dart';
import '../../../core/constants/constants.dart';
import '../controllers/memory_controller.dart';
import '../../../data/models/memory.dart';
import '../widgets/memory_form.dart';
import '../../../core/providers/current_user_provider.dart';

class MemoryCreateView extends ConsumerStatefulWidget {
  final LatLng initialLocation;

  const MemoryCreateView({super.key, required this.initialLocation});

  @override
  ConsumerState<MemoryCreateView> createState() => _MemoryCreateViewState();
}

class _MemoryCreateViewState extends ConsumerState<MemoryCreateView> {
  DateTime? _selectedDate;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _mapController = MapController();
  late LatLng location;

  @override
  void initState() {
    super.initState();
    location = widget.initialLocation;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
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

  Future<void> _handleSubmit() async {
    final memoryController = ref.read(memoryControllerProvider.notifier);

    if (!_formKey.currentState!.validate()) return;

    final newMemory = Memory(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: GeoPoint(location.latitude, location.longitude),
      happenedAt: _selectedDate!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final userAsync = ref.watch(currentUserProvider);
    if (userAsync is AsyncLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando usuario...'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    } else if (userAsync is AsyncError) {
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

    newMemory.participants.add(UserRole(user: user, role: MemoryRole.creator));

    try {
      await memoryController.createMemory(newMemory, user.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recuerdo creado correctamente'),
          backgroundColor: AppColors.accentColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear el recuerdo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoryControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Crear nuevo recuerdo'),
        backgroundColor: AppColors.primaryColor,
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
              AppFormButtons(
                primaryLabel: 'Guardar recuerdo',
                onPrimaryPressed: _handleSubmit,
                secondaryLabel: 'Cancelar',
                onSecondaryPressed: () => Navigator.of(context).pop(),
                isProcessing: state.isLoading,
              ),

              const SizedBox(height: 24),

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
                    initialCenter: location,
                    initialZoom: 17,
                    minZoom: 2.0,
                    maxZoom: 18.0,
                    onLongPress: (tapPosition, latLng) {
                      setState(() {
                        location = latLng;
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
                          point: location,
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
            ],
          ),
        ),
      ),
    );
  }
}
