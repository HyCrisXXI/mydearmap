// ...existing code...
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../controllers/memory_controller.dart';
import '../../../data/models/memory.dart';
import '../widgets/memory_form.dart';
import '../widgets/memory_action_buttons.dart';

class MemoryCreateView extends ConsumerStatefulWidget {
  const MemoryCreateView({super.key});

  @override
  ConsumerState<MemoryCreateView> createState() => _MemoryCreateViewState();
}

class _MemoryCreateViewState extends ConsumerState<MemoryCreateView> {
  DateTime? _selectedDate;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

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
      id: "",
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: null,
      happenedAt: _selectedDate!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // participants: [UserRole(user: , role: MemoryRole.creator)],
    );

    try {
      await memoryController.createMemory(newMemory);
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
                titleValidator: (value) => (value == null || value.isEmpty) ? 'Ingresa un título' : null,
                dateValidator: (_) => _selectedDate == null ? 'Selecciona la fecha del recuerdo' : null,
              ),
              const SizedBox(height: AppSizes.paddingLarge),
              MemoryActionButtons(
                editing: true,
                isLoading: state.isLoading,
                onCancel: () => Navigator.of(context).pop(),
                onSave: _handleSubmit,
                primaryLabel: 'Guardar recuerdo',
                cancelLabel: 'Cancelar',
              ),
            ],
          ),
        ),
      ),
    );
  }
}