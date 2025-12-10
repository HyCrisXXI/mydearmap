// lib/features/profile/views/profile_form_view.dart

import 'package:mydearmap/core/utils/media_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/widgets/app_form_buttons.dart';
import 'package:mydearmap/core/utils/form_validation_mixin.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/features/profile/controllers/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_svg/flutter_svg.dart';

class ProfileEditView extends ConsumerStatefulWidget {
  const ProfileEditView({super.key, required this.user});

  final User user;

  @override
  ConsumerState<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends ConsumerState<ProfileEditView>
    with FormValidationMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _numberController = TextEditingController();
  final _birthDateController = TextEditingController();

  DateTime? _selectedBirthDate;
  Gender _selectedGender = Gender.other;
  String? _newProfileUrl;
  bool _isUploadingAvatar = false;

  String? _nameError;
  String? _emailError;
  String? _numberError;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    _numberController.text = widget.user.number ?? '';
    _selectedBirthDate = widget.user.birthDate;
    _selectedGender = widget.user.gender;

    if (widget.user.birthDate != null) {
      _birthDateController.text =
          '${widget.user.birthDate!.day.toString().padLeft(2, '0')}/'
          '${widget.user.birthDate!.month.toString().padLeft(2, '0')}/'
          '${widget.user.birthDate!.year}';
    }

    _nameController.addListener(() {
      setState(() => _nameError = validateName(_nameController.text));
    });

    _emailController.addListener(() {
      setState(() => _emailError = validateEmail(_emailController.text));
    });

    _numberController.addListener(() {
      setState(
        () => _numberError = validatePhoneNumber(_numberController.text),
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return canSubmitForm(
      name: _nameController.text,
      email: _emailController.text,
      number: _numberController.text,
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final croppedFile = await MediaUtils.pickAndCropImage(context: context);

    if (croppedFile == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final bytes = await croppedFile.readAsBytes();
      final client = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Ensure extension is .jpg
      final sanitizedName = 'avatar_$timestamp.jpg';

      final storagePath =
          'avatars/${widget.user.id}_${timestamp}_$sanitizedName';

      await client.storage
          .from('media')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Guardar solo el nombre del archivo, no la URL completa
      setState(() => _newProfileUrl = storagePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen subida correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir la imagen: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, completa correctamente todos los campos requeridos',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cambios'),
        content: const Text(
          '¿Estás seguro de que deseas guardar los cambios en tu perfil?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final controller = ref.read(profileControllerProvider.notifier);
    final emailChanged = _emailController.text.trim() != widget.user.email;

    try {
      await controller.updateProfile(
        userId: widget.user.id,
        name: _nameController.text.trim(),
        email: emailChanged ? _emailController.text.trim() : null,
        number: _numberController.text.trim().isEmpty
            ? null
            : _numberController.text.trim(),
        birthDate: _selectedBirthDate,
        gender: _selectedGender.name,
        profileUrl: _newProfileUrl,
      );

      if (!mounted) return;

      // Mostrar mensaje de éxito
      if (emailChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Perfil actualizado. Revisa tu nuevo correo para verificar el cambio.',
            ),
            backgroundColor: AppColors.accentColor,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppColors.accentColor,
          ),
        );
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString();

      // Detectar si es el error de rate limit
      if (errorMessage.contains('10 seconds') ||
          errorMessage.contains('security purposes')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Debes esperar al menos 10 segundos entre cambios de correo.',
            ),
            backgroundColor: Colors.orangeAccent,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el perfil: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(profileControllerProvider);

    String? currentAvatarUrl;
    if (_newProfileUrl != null) {
      currentAvatarUrl = buildMediaUrl(_newProfileUrl!);
    } else {
      currentAvatarUrl = buildAvatarUrl(widget.user.profileUrl);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
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
                    left: AppSizes.paddingLarge,
                    right: AppSizes.paddingLarge,
                    bottom: 8.0,
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
                      const Text('Editar perfil', style: AppTextStyles.title),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSizes.paddingLarge,
                      right: AppSizes.paddingLarge,
                      bottom: AppSizes.paddingLarge,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: _isUploadingAvatar
                                  ? null
                                  : _pickAndUploadAvatar,
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
                                  backgroundColor: AppColors.primaryColor,
                                  backgroundImage: currentAvatarUrl != null
                                      ? NetworkImage(currentAvatarUrl)
                                      : null,
                                  child: currentAvatarUrl == null
                                      ? Text(
                                          widget.user.name.isNotEmpty
                                              ? widget.user.name[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            color: Color.fromARGB(
                                              255,
                                              17,
                                              17,
                                              17,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            if (_isUploadingAvatar)
                              const Positioned.fill(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Transform.translate(
                                offset: const Offset(5, 5),
                                child: IconButton(
                                  style: AppButtonStyles.circularIconButton,
                                  onPressed: _isUploadingAvatar
                                      ? null
                                      : _pickAndUploadAvatar,
                                  icon: SvgPicture.asset(AppIcons.pencil),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca para cambiar la imagen',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: AppSizes.paddingLarge),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo *',
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                            errorText: _nameError,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico *',
                            prefixIcon: const Icon(Icons.email),
                            border: const OutlineInputBorder(),
                            errorText: _emailError,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        TextField(
                          controller: _numberController,
                          decoration: InputDecoration(
                            labelText: 'Número de teléfono (opcional)',
                            prefixIcon: const Icon(Icons.phone),
                            border: const OutlineInputBorder(),
                            errorText: _numberError,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          onTap: _pickBirthDate,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        DropdownButtonFormField<Gender>(
                          initialValue: _selectedGender,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Género',
                            prefixIcon: Icon(Icons.wc),
                            border: OutlineInputBorder(),
                          ),
                          items: Gender.values
                              .map(
                                (gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(_genderLabel(gender)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedGender = value);
                            }
                          },
                        ),
                        const SizedBox(height: AppSizes.paddingLarge),
                        AppFormButtons(
                          primaryLabel: 'Guardar cambios',
                          onPrimaryPressed: _canSave ? _saveProfile : null,
                          secondaryLabel: 'Cancelar',
                          onSecondaryPressed: () => Navigator.of(context).pop(),
                          isProcessing:
                              controllerState.isLoading || _isUploadingAvatar,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ); // Scaffold
  }

  String _genderLabel(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Masculino';
      case Gender.female:
        return 'Femenino';
      case Gender.other:
        return 'Otro';
    }
  }
}
