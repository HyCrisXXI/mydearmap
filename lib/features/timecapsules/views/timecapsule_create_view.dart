import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mydearmap/core/constants/app_icons.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/timecapsules/controllers/timecapsule_controller.dart';
import 'package:mydearmap/features/memories/widgets/memory_selection_widget.dart';

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
    final result = await Navigator.of(context).push<List<Memory>>(
      MaterialPageRoute(
        builder: (_) => MemorySelectionWidget(
          availableMemories: availableMemories,
          selectedMemories: _selectedMemories,
          onSelectionDone: (selected) {
            Navigator.of(context).pop(selected);
          },
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
                          icon: SvgPicture.asset(AppIcons.plus),
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
                            icon: SvgPicture.asset(AppIcons.x),
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
