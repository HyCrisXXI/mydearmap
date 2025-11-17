import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/timecapsule/controllers/timecapsule_controller.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:mydearmap/core/constants/constants.dart';

class TimeCapsuleCreateView extends ConsumerStatefulWidget {
  const TimeCapsuleCreateView({super.key, this.capsuleId});

  final String? capsuleId; // null for create, id for edit

  @override
  ConsumerState<TimeCapsuleCreateView> createState() =>
      _TimeCapsuleCreateViewState();
}

class _TimeCapsuleCreateViewState extends ConsumerState<TimeCapsuleCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _openAt;
  List<Memory> _selectedMemories = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.capsuleId != null) {
      _loadCapsuleForEdit();
    }
  }

  Future<void> _loadCapsuleForEdit() async {
    // Forzar obtener los recuerdos de la cápsula y marcarlos como seleccionados
    final capsuleMemories = await ref.read(
      timeCapsuleMemoriesProvider(widget.capsuleId!).future,
    );
    setState(() => _selectedMemories = capsuleMemories);

    final capsule = await ref.read(
      timeCapsuleProvider(widget.capsuleId!).future,
    );
    if (capsule != null) {
      _titleController.text = capsule.title;
      _descriptionController.text = capsule.description ?? '';
      _openAt = capsule.openAt;
      setState(() {});
    }
  }

  Future<void> _pickOpenAt() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _openAt ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _openAt = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _openAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) throw Exception('Usuario no encontrado');

      if (widget.capsuleId == null) {
        await ref
            .read(timeCapsuleControllerProvider.notifier)
            .createTimeCapsule(
              creatorId: user.id,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              openAt: _openAt!,
              memoryIds: _selectedMemories.map((m) => m.id!).toList(),
            );
      } else {
        await ref
            .read(timeCapsuleControllerProvider.notifier)
            .updateTimeCapsule(
              capsuleId: widget.capsuleId!,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              openAt: _openAt!,
              memoryIds: _selectedMemories.map((m) => m.id!).toList(),
            );
      }

      // RESETEA la caché antes de refrescar el provider
      ref.read(userMemoriesCacheProvider.notifier).reset();
      ref.invalidate(userMemoriesProvider);
      ref.invalidate(timeCapsuleProvider);
      ref.invalidate(timeCapsuleMemoriesProvider);

      if (mounted) {
        Navigator.of(context).pop(true); // Devuelve true para refrescar padre
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cápsula guardada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addMemories() async {
    final availableMemories = await _getAvailableMemories();
    if (!mounted) return;
    // Pasar ids seleccionados, no objetos
    final result = await Navigator.of(context).push<List<Memory>>(
      MaterialPageRoute(
        builder: (_) => MemorySelectionView(
          availableMemories: availableMemories,
          selectedMemories: _selectedMemories,
        ),
      ),
    );
    if (result != null) {
      setState(() => _selectedMemories = result);
    }
  }

  Future<List<Memory>> _getAvailableMemories() async {
    // Siempre obtener la última lista de recuerdos del usuario
    final userMemories = await ref.read(userMemoriesProvider.future);
    if (widget.capsuleId == null) return userMemories;

    // Para editar, incluir los recuerdos de la cápsula aunque no estén en userMemories
    final capsuleMemories = await ref.read(
      timeCapsuleMemoriesProvider(widget.capsuleId!).future,
    );
    final all = [...userMemories];
    for (final cm in capsuleMemories) {
      if (!all.any((m) => m.id == cm.id)) all.add(cm);
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.capsuleId == null ? 'Crear Cápsula' : 'Editar Cápsula',
        ),
        actions: [
          if (!_isLoading)
            TextButton(onPressed: _save, child: const Text('Guardar')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Título *'),
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'Requerido' : null,
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                      maxLines: 3,
                    ),
                    ListTile(
                      title: const Text('Fecha de apertura *'),
                      subtitle: Text(
                        _openAt != null
                            ? '${_openAt!.day}/${_openAt!.month}/${_openAt!.year}'
                            : 'Seleccionar',
                      ),
                      onTap: _pickOpenAt,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Recuerdos seleccionados:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addMemories,
                        ),
                      ],
                    ),
                    if (_selectedMemories.isEmpty)
                      const Text('Ninguno seleccionado')
                    else
                      ..._selectedMemories.map(
                        (memory) => ListTile(
                          title: Text(memory.title),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => setState(
                              () => _selectedMemories.remove(memory),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class MemorySelectionView extends StatefulWidget {
  const MemorySelectionView({
    super.key,
    required this.availableMemories,
    required this.selectedMemories,
  });

  final List<Memory> availableMemories;
  final List<Memory> selectedMemories;

  @override
  State<MemorySelectionView> createState() => _MemorySelectionViewState();
}

class _MemorySelectionViewState extends State<MemorySelectionView> {
  late List<Memory> _selected;

  @override
  void initState() {
    super.initState();
    // Usar ids para asegurar que los seleccionados se marquen correctamente
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
            onPressed: () => Navigator.of(context).pop(_selected),
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
          childAspectRatio: 170 / 192, // 170 ancho, 160+32 alto
        ),
        itemCount: widget.availableMemories.length,
        itemBuilder: (context, index) {
          final memory = widget.availableMemories[index];
          final isSelected = _isMemorySelected(memory);
          final mainMedia = memory.media.isNotEmpty ? memory.media.first : null;
          final imageUrl = mainMedia != null && mainMedia.url != null
              ? buildMediaPublicUrl(mainMedia.url)
              : null;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 170,
                maxHeight: 192, // 160 + espacio para el título
              ),
              child: AspectRatio(
                aspectRatio: 170 / 192,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 170 / 160,
                          child: Container(
                            decoration: AppDecorations.cardMemoryDecoration,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: Icon(Icons.image, size: 50),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 24,
                          child: Center(
                            child: Text(
                              memory.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
