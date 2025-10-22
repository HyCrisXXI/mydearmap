// lib/features/memories/widgets/memory_action_buttons.dart
import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

class MemoryActionButtons extends StatelessWidget {
  final bool editing;
  final bool isLoading;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final VoidCallback? onEdit;
  final String? primaryLabel;
  final String? cancelLabel;

  const MemoryActionButtons({
    super.key,
    required this.editing,
    required this.isLoading,
    this.onCancel,
    this.onSave,
    this.onEdit,
    this.primaryLabel,
    this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 238, 0, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
              ),
              onPressed: isLoading ? null : onCancel,
              child: Text(
                cancelLabel ?? 'Cancelar',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
              ),
              onPressed: isLoading ? null : onSave,
              child: Text(
                primaryLabel ?? 'Guardar cambios',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
        ),
        onPressed: isLoading ? null : onEdit,
        child: Text(
          primaryLabel ?? 'Editar recuerdo',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
