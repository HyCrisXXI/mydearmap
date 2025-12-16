import 'dart:typed_data';
import 'package:mydearmap/core/utils/media_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/relation_group.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/features/relations/controllers/relation_group_controller.dart';

class RelationGroupCreateView extends ConsumerStatefulWidget {
  const RelationGroupCreateView({super.key, this.initialGroup});

  final RelationGroup? initialGroup;

  @override
  ConsumerState<RelationGroupCreateView> createState() =>
      _RelationGroupCreateViewState();
}

class _RelationGroupCreateViewState
    extends ConsumerState<RelationGroupCreateView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _saving = false;
  final Set<String> _selectedMemberIds = <String>{};

  bool get _isEditMode => widget.initialGroup != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialGroup?.name);
    if (_isEditMode) {
      _selectedMemberIds.addAll(widget.initialGroup!.members.map((u) => u.id));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final croppedFile = await MediaUtils.pickAndCropImage(context: context);
    if (croppedFile == null) return;

    final bytes = await croppedFile.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageFilename =
          'group_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref
        .read(currentUserProvider)
        .maybeWhen(data: (user) => user, orElse: () => null);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para continuar')),
      );
      return;
    }

    setState(() => _saving = true);
    final name = _nameController.text.trim();

    try {
      final controller = ref.read(relationGroupControllerProvider.notifier);

      if (_isEditMode) {
        await controller.updateGroup(
          groupId: widget.initialGroup!.id,
          creatorId: currentUser.id,
          name: name,
          photoBytes: _imageBytes,
          photoFilename: _imageFilename,
          memberIds: _selectedMemberIds.toList(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo actualizado correctamente')),
        );
      } else {
        await controller.createGroup(
          creatorId: currentUser.id,
          name: name,
          photoBytes: _imageBytes,
          photoFilename: _imageFilename,
          memberIds: _selectedMemberIds.toList(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo creado correctamente')),
        );
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Inicia sesión para crear un grupo')),
          );
        }

        final relationsAsync = ref.watch(userRelationsProvider(user.id));

        return relationsAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
          data: (relations) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppIcons.profileBG),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSizes.upperPadding,
                            left: 20,
                            right: 20,
                            bottom: 10,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: SvgPicture.asset(AppIcons.chevronLeft),
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: AppButtonStyles.circularIconButton,
                                ),
                              ),
                              Text(
                                _isEditMode ? 'Editar grupo' : 'Nuevo grupo',
                                style: AppTextStyles.title,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: 80,
                                  height: AppSizes.buttonHeight,
                                  child: FilledButton(
                                    onPressed: _saving ? null : _handleSubmit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          AppColors.buttonBackground,
                                      foregroundColor:
                                          AppColors.buttonForeground,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSizes.borderRadius,
                                        ),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Listo',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 20,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (_imageBytes != null) {
                                              _showFullImage(
                                                context,
                                                imageBytes: _imageBytes,
                                              );
                                            } else if (widget
                                                    .initialGroup
                                                    ?.photoUrl !=
                                                null) {
                                              _showFullImage(
                                                context,
                                                imageUrl: buildGroupPhotoUrl(
                                                  widget.initialGroup!.photoUrl,
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.primaryColor,
                                                width: 1,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 60,
                                              backgroundImage:
                                                  _imageBytes != null
                                                  ? MemoryImage(_imageBytes!)
                                                  : (widget
                                                                .initialGroup
                                                                ?.photoUrl !=
                                                            null &&
                                                        _imageBytes == null)
                                                  ? NetworkImage(
                                                      buildGroupPhotoUrl(
                                                        widget
                                                            .initialGroup!
                                                            .photoUrl,
                                                      )!,
                                                    )
                                                  : null,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              child:
                                                  (_imageBytes == null &&
                                                      widget
                                                              .initialGroup
                                                              ?.photoUrl ==
                                                          null)
                                                  ? const Icon(
                                                      Icons.group,
                                                      size: 60,
                                                      color: Colors.grey,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Transform.translate(
                                            offset: const Offset(5, 5),
                                            child: IconButton(
                                              style: AppButtonStyles
                                                  .circularIconButton,
                                              onPressed: _saving
                                                  ? null
                                                  : _pickImage,
                                              icon: SvgPicture.asset(
                                                AppIcons.pencil,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre del grupo',
                                      hintText: 'Familia, Amigos del cole…',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'El grupo necesita un nombre';
                                      }
                                      if (value.trim().length < 3) {
                                        return 'Usa al menos 3 caracteres';
                                      }
                                      return null;
                                    },
                                    textInputAction: TextInputAction.done,
                                    enabled: !_saving,
                                  ),
                                  const SizedBox(height: 32),
                                  _buildMembersSection(relations),
                                  const SizedBox(height: 32),
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
          },
        );
      },
    );
  }

  Widget _buildMembersSection(List<UserRelation> relations) {
    final relationMap = {
      for (var r in relations) r.relatedUser.id: r.relatedUser,
    };
    final initialMembersMap = widget.initialGroup != null
        ? {for (var m in widget.initialGroup!.members) m.id: m}
        : <String, dynamic>{};

    final selectedUsers = _selectedMemberIds
        .map((id) {
          return relationMap[id] ?? initialMembersMap[id];
        })
        .where((u) => u != null)
        .cast<dynamic>()
        .toList();

    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add Button
          // Add Button
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _showAddPeopleDialog(relations),
                  style: AppButtonStyles.circularIconButton,
                  icon: SvgPicture.asset(AppIcons.plus),
                ),
              ],
            ),
          ),
          // Selected People
          if (selectedUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  'Añadir miembros',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            )
          else
            ...selectedUsers.map((user) {
              final avatarUrl = buildAvatarUrl(user.profileUrl);
              return GestureDetector(
                onTap: () => _showRemovePersonDialog(user),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                              image: avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: Colors.grey[200],
                            ),
                            child: avatarUrl == null
                                ? Center(
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name.isNotEmpty ? user.name : user.email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Miembro',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showAddPeopleDialog(List<UserRelation> relations) async {
    final tempSelected = Set<String>.from(_selectedMemberIds);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Seleccionar personas'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return relations.isEmpty
                    ? const Text('No hay relaciones disponibles')
                    : ListView(
                        shrinkWrap: true,
                        children: relations.map((r) {
                          final related = r.relatedUser;
                          final id = related.id;
                          final isSelected = tempSelected.contains(id);
                          final avatarUrl = buildAvatarUrl(related.profileUrl);

                          return InkWell(
                            onTap: () {
                              setStateDialog(() {
                                if (isSelected) {
                                  tempSelected.remove(id);
                                } else {
                                  tempSelected.add(id);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 4.0,
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                      image: avatarUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(avatarUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: Colors.grey[200],
                                    ),
                                    child: avatarUrl == null
                                        ? Center(
                                            child: Text(
                                              related.name.isNotEmpty
                                                  ? related.name[0]
                                                        .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Name
                                  Expanded(
                                    child: Text(
                                      related.name.isNotEmpty
                                          ? related.name
                                          : related.email,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Custom Checkbox
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.accentColor
                                          : Colors.transparent,
                                      border: isSelected
                                          ? null
                                          : Border.all(
                                              color: Colors.grey,
                                              width: 2,
                                            ),
                                    ),
                                    child: isSelected
                                        ? Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: SvgPicture.asset(
                                              AppIcons.check,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Colors.white,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedMemberIds.clear();
                  _selectedMemberIds.addAll(tempSelected);
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRemovePersonDialog(dynamic user) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.name.isNotEmpty ? user.name : user.email,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: SvgPicture.asset(
                  AppIcons.trash,
                  colorFilter: const ColorFilter.mode(
                    Colors.redAccent,
                    BlendMode.srcIn,
                  ),
                ),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  setState(() {
                    _selectedMemberIds.remove(user.id);
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullImage(
    BuildContext context, {
    String? imageUrl,
    Uint8List? imageBytes,
  }) {
    if (imageUrl == null && imageBytes == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(500),
          child: imageBytes != null
              ? Image.memory(imageBytes, fit: BoxFit.cover)
              : Image.network(imageUrl!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
