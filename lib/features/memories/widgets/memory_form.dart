// lib/features/memories/widgets/memory_form.dart
import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';

class MemoryForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController dateController;
  final bool readOnly;
  final VoidCallback? onPickDate;
  final String? Function(String?)? titleValidator;
  final String? Function(String?)? dateValidator;

  const MemoryForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.dateController,
    this.readOnly = true,
    this.onPickDate,
    this.titleValidator,
    this.dateValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: titleController,
          readOnly: readOnly,
          decoration: const InputDecoration(
            labelText: 'Título',
            border: OutlineInputBorder(),
          ),
          validator: titleValidator,
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        TextFormField(
          controller: dateController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Fecha del recuerdo',
            border: const OutlineInputBorder(),
            suffixIcon: readOnly
                ? null
                : IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: onPickDate,
                  ),
          ),
          onTap: readOnly ? null : onPickDate,
          validator: dateValidator,
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        TextFormField(
          controller: descriptionController,
          readOnly: readOnly,
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
