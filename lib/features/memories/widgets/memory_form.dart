// lib/features/memories/widgets/memory_form.dart
import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/data/models/memory.dart';

class MemoryForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController dateController;
  final bool readOnly;
  final VoidCallback? onPickDate;
  final String? Function(String?)? titleValidator;
  final String? Function(String?)? dateValidator;
  final List<UserRole> participants;
  final void Function(UserRole participant) onRemoveParticipant;
  final void Function(UserRole participant) onChangeRole;

  const MemoryForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.dateController,
    this.readOnly = true,
    this.onPickDate,
    this.titleValidator,
    this.dateValidator,
    this.participants = const [],
    required this.onRemoveParticipant,
    required this.onChangeRole,
  });

  @override
  State<MemoryForm> createState() => _MemoryFormState();
}

class _MemoryFormState extends State<MemoryForm> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.titleController,
          readOnly: widget.readOnly,
          decoration: const InputDecoration(
            labelText: 'Título',
            border: OutlineInputBorder(),
          ),
          validator: widget.titleValidator,
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        TextFormField(
          controller: widget.dateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Fecha del recuerdo',
            border: const OutlineInputBorder(),
            suffixIcon: widget.readOnly
                ? null
                : IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: widget.onPickDate,
                  ),
          ),
          onTap: widget.readOnly ? null : widget.onPickDate,
          validator: widget.dateValidator,
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        TextFormField(
          controller: widget.descriptionController,
          readOnly: widget.readOnly,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
