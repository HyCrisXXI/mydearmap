import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/features/relations/controllers/relation_group_controller.dart';

class RelationGroupCreateView extends ConsumerStatefulWidget {
  const RelationGroupCreateView({super.key});

  @override
  ConsumerState<RelationGroupCreateView> createState() =>
      _RelationGroupCreateViewState();
}

class _RelationGroupCreateViewState
    extends ConsumerState<RelationGroupCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _saving = false;
  final Set<String> _selectedMemberIds = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageFilename = file.name;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider).maybeWhen(
          data: (user) => user,
          orElse: () => null,
        );
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para continuar')),
      );
      return;
    }

    setState(() => _saving = true);
    final name = _nameController.text.trim();

    try {
      await ref.read(relationGroupControllerProvider.notifier).createGroup(
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
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear el grupo: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Inicia sesión para crear un grupo')),
          );
        }

        final relationsAsync = ref.watch(userRelationsProvider(user.id));

        return relationsAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            body: Center(child: Text('Error: $error')),
          ),
          data: (relations) => Scaffold(
            appBar: AppBar(
              title: const Text('Nuevo grupo'),
              leading: IconButton(
                icon: SvgPicture.asset(AppIcons.chevronLeft),
                onPressed: () => Navigator.of(context).pop(),
                style: AppButtonStyles.circularIconButton,
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(60),
                        onTap: _saving ? null : _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: _imageBytes != null
                              ? MemoryImage(_imageBytes!)
                              : null,
                          backgroundColor: Colors.grey.shade200,
                          child: _imageBytes == null
                              ? const Icon(Icons.photo_camera, size: 28)
                              : null,
                        ),
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
                        if (value == null || value.trim().isEmpty) {
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
                    const SizedBox(height: 24),
                    Text(
                      'Integrantes (opcional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildMembersSection(relations),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                            _saving ? 'Creando grupo...' : 'Crear grupo'),
                        onPressed: _saving ? null : _handleSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersSection(List<UserRelation> relations) {
    if (relations.isEmpty) {
      return const Text('Aún no tienes vínculos para añadir al grupo.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: relations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final relation = relations[index];
        final relationId = relation.relatedUser.id;
        final selected = _selectedMemberIds.contains(relationId);
        final label = _relationDisplayName(relation);
        final avatarUrl = buildAvatarUrl(relation.relatedUser.profileUrl);
        final fallbackLetter =
            label.isNotEmpty ? label[0].toUpperCase() : '?';

        return CheckboxListTile(
          value: selected,
          onChanged: _saving
              ? null
              : (checked) {
                  setState(() {
                    if (checked ?? false) {
                      _selectedMemberIds.add(relationId);
                    } else {
                      _selectedMemberIds.remove(relationId);
                    }
                  });
                },
          controlAffinity: ListTileControlAffinity.trailing,
          title: Text(label),
          secondary: CircleAvatar(
            radius: 24,
            backgroundColor:
                avatarUrl == null ? Colors.grey.shade200 : Colors.transparent,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    fallbackLetter,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  )
                : null,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        );
      },
    );
  }

  String _relationDisplayName(UserRelation relation) {
    final name = relation.relatedUser.name.trim();
    if (name.isNotEmpty) return name;
    final email = relation.relatedUser.email.trim();
    if (email.isNotEmpty) return email;
    return 'Usuario sin nombre';
  }
}
