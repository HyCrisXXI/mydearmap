// lib/features/memory/views/memory_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../controllers/memory_controller.dart';
import '../../../data/models/memory.dart';
import '../widgets/memory_form.dart';
import '../widgets/memory_action_buttons.dart';

class MemoryView extends ConsumerStatefulWidget {
  final String memoryId;

  const MemoryView({super.key, required this.memoryId});

  @override
  ConsumerState<MemoryView> createState() => _MemoryViewState();
}

class _MemoryViewState extends ConsumerState<MemoryView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  bool _editing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadMemory() async {
    setState(() => _isLoading = true);
    try {
      final memory = await ref.read(memoryControllerProvider.notifier).getMemoryById(widget.memoryId);
      if (memory != null) {
        _titleController.text = memory.title;
        _descriptionController.text = memory.description ?? '';
        _selectedDate = memory.happenedAt;
        _dateController.text = '${_selectedDate!.day.toString().padLeft(2, '0')}/'
            '${_selectedDate!.month.toString().padLeft(2, '0')}/'
            '${_selectedDate!.year}';
      }
    } catch (_) {
      // ignore, UI will show error later
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<DateTime?> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
    return picked;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final existing = await ref.read(memoryControllerProvider.notifier).getMemoryById(widget.memoryId);
      if (existing == null) throw Exception('Memory no encontrada');

      final updated = Memory(
        id: existing.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        location: existing.location,
        happenedAt: _selectedDate ?? existing.happenedAt,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      await ref.read(memoryControllerProvider.notifier).updateMemory(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recuerdo actualizado'), backgroundColor: AppColors.accentColor),
      );
      setState(() {
        _editing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMemory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del recuerdo'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit),
              onPressed: () {
                if (_editing) {
                  // cancelar edición: recargar valores
                  _loadMemory();
                  setState(() => _editing = false);
                } else {
                  setState(() => _editing = true);
                }
              },
            ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmAndDelete(),
            ),
        ],
      ),
      backgroundColor: AppColors.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      readOnly: !_editing,
                      onPickDate: _pickDate,
                      titleValidator: (value) => (value == null || value.isEmpty) ? 'Ingresa un título' : null,
                      dateValidator: (_) => _selectedDate == null ? 'Selecciona la fecha del recuerdo' : null,
                    ),
                    const SizedBox(height: AppSizes.paddingLarge),
                    MemoryActionButtons(
                      editing: _editing,
                      isLoading: _isLoading,
                      onCancel: () {
                        _loadMemory();
                        setState(() => _editing = false);
                      },
                      onSave: _save,
                      onEdit: () => setState(() => _editing = true),
                      primaryLabel: _editing ? 'Guardar cambios' : 'Editar recuerdo',
                      cancelLabel: 'Cancelar',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este recuerdo? Esta acción no se puede deshacer.'),
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

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(memoryControllerProvider.notifier).deleteMemory(widget.memoryId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recuerdo eliminado'), backgroundColor: AppColors.accentColor),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
