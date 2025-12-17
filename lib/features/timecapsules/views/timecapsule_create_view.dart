import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/widgets/pulse_button.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:mydearmap/data/models/media.dart';
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
    setState(() => _selectedMemories = [...capsuleMemories]);

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

  Media? _pickDisplayMedia(Memory memory) {
    Media? fallback;
    for (final media in memory.media) {
      final url = media.url;
      if (url == null || url.isEmpty) continue;
      fallback ??= media;
      if (media.type == MediaType.image) return media;
    }
    return fallback;
  }

  Widget _buildMemoryThumbnail(Memory memory) {
    const size = 56.0;
    final media = _pickDisplayMedia(memory);
    final imageUrl = buildMediaPublicUrl(media?.url);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Icon(
        Icons.photo,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );

    if (imageUrl == null) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppIcons.profileBG),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            top: false,
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.upperPadding,
                    left: 20,
                    right: 20,
                    bottom: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            PulseButton(
                              child: IconButton(
                                icon: SvgPicture.asset(AppIcons.chevronLeft),
                                onPressed: () => Navigator.of(context).pop(),
                                style: AppButtonStyles.circularIconButton,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.capsuleId == null
                                    ? 'Crear Cápsula'
                                    : 'Editar Cápsula',
                                style: AppTextStyles.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: AppSizes.buttonHeight,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.buttonBackground,
                            foregroundColor: AppColors.buttonForeground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.borderRadius,
                              ),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Guardar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Título',
                              hintText: 'Ej: Cumpleaños 2025',
                            ),
                            style: AppTextStyles.textField.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            validator: (v) =>
                                v?.trim().isEmpty ?? true ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripción (Opcional)',
                              hintText: '¿De qué trata esta cápsula?',
                            ),
                            minLines: 1,
                            maxLines: null,
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Fecha de apertura',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickOpenAt,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppColors.buttonBackground,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _openAt != null
                                        ? '${_openAt!.day}/${_openAt!.month}/${_openAt!.year}'
                                        : 'Seleccionar fecha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _openAt != null
                                          ? AppColors.textColor
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recuerdos',
                                style: AppTextStyles.subtitle,
                              ),
                              PulseButton(
                                child: IconButton(
                                  onPressed: _addMemories,
                                  style: AppButtonStyles.circularIconButton,
                                  icon: SvgPicture.asset(AppIcons.plus),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_selectedMemories.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  'Añade recuerdos para guardar en esta cápsula.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _selectedMemories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final memory = _selectedMemories[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                      leading: _buildMemoryThumbnail(memory),
                                      title: Text(
                                        memory.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: SvgPicture.asset(AppIcons.trash),
                                        onPressed: () => setState(
                                          () =>
                                              _selectedMemories.remove(memory),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
