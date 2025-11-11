// lib/features/memories/widgets/memory_form.dart
import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/models/memory.dart';

class MemoryForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController dateController;
  final bool readOnly;
  final VoidCallback? onPickDate;
  final String? Function(String?)? titleValidator;
  final String? Function(String?)? dateValidator;
  final List<UserRole> relatedPeople;
  final List<User> availableUsers;
  final void Function(UserRole) onAddUser;
  final void Function(UserRole) onRemoveUser;
  final void Function(UserRole) onChangeRole;

  const MemoryForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.dateController,
    this.readOnly = true,
    this.onPickDate,
    this.titleValidator,
    this.dateValidator,
    this.relatedPeople = const [],
    this.availableUsers = const [],
    required this.onAddUser,
    required this.onRemoveUser,
    required this.onChangeRole,
  });

  @override
  State<MemoryForm> createState() => _MemoryFormState();
}

class _MemoryFormState extends State<MemoryForm> {
  final _personController = TextEditingController();
  TextEditingController? _autocompleteController;
  bool _hasMatch = false;

  @override
  void initState() {
    super.initState();
    _personController.addListener(() {
      final text = _personController.text.trim().toLowerCase();
      final match = widget.availableUsers.any(
        (u) =>
            u.name.toLowerCase() == text ||
            u.email.toLowerCase().contains(text),
      );
      if (match != _hasMatch) setState(() => _hasMatch = match);
    });
  }

  @override
  void dispose() {
    _personController.dispose();
    super.dispose();
  }

  void _handleAddManual(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final match = widget.availableUsers.firstWhere(
      (u) => u.name.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => User(
        id: '',
        name: trimmed,
        email: '',
        gender: Gender.other,
        createdAt: DateTime.now(),
      ),
    );
    if (match.id.isEmpty) return; // don't add manual arbitrary users
    final role = MemoryRole.participant;
    widget.onAddUser(UserRole(user: match, role: role));
    _personController.clear();
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
        const SizedBox(height: AppSizes.paddingMedium),
        Text(
          'Personas relacionadas',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        Wrap(
          spacing: AppSizes.paddingSmall,
          runSpacing: AppSizes.paddingSmall,
          children: widget.relatedPeople.map((ur) {
            final label = ur.user.name;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(label + ' (${ur.role.name})'),
                  deleteIcon: widget.readOnly ? null : const Icon(Icons.close),
                  onDeleted: widget.readOnly
                      ? null
                      : () => widget.onRemoveUser(ur),
                  backgroundColor: Colors.grey[100],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (!widget.readOnly)
                  PopupMenuButton<MemoryRole>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (role) {
                      widget.onChangeRole(UserRole(user: ur.user, role: role));
                    },
                    itemBuilder: (context) => MemoryRole.values
                        .where((r) => r != MemoryRole.creator)
                        .map(
                          (r) => PopupMenuItem<MemoryRole>(
                            value: r,
                            child: Text(r.name),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(width: AppSizes.paddingSmall),
              ],
            );
          }).toList(),
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: AppSizes.paddingSmall),
          Row(
            children: [
              Expanded(
                child: Autocomplete<User>(
                  displayStringForOption: (u) => u.name,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final query = textEditingValue.text.toLowerCase();
                    return widget.availableUsers.where((u) {
                      final already = widget.relatedPeople.any(
                        (sel) => sel.user.id == u.id || sel.user.name == u.name,
                      );
                      if (already) return false;
                      if (query.isEmpty) return true;
                      return u.name.toLowerCase().contains(query) ||
                          u.email.toLowerCase().contains(query);
                    }).toList();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        // Keep a reference to the internal Autocomplete controller
                        _autocompleteController = controller;
                        controller.text = _personController.text;
                        controller.addListener(() {
                          _personController.text = controller.text;
                          _personController.selection = controller.selection;
                        });
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText:
                                'Buscar persona (selecciona de la lista)',
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                  onSelected: (selected) {
                    widget.onAddUser(
                      UserRole(user: selected, role: MemoryRole.participant),
                    );
                    // Clear both controllers to avoid leftover text in the Autocomplete field
                    try {
                      _autocompleteController?.clear();
                    } catch (_) {}
                    _personController.clear();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              const SizedBox(width: AppSizes.paddingSmall),
            ],
          ),
          if (!_hasMatch && _personController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.paddingSmall),
              child: Text(
                'No se encontró coincidencia. Selecciona una persona de tus relaciones.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
              ),
            ),
        ],
      ],
    );
  }
}
