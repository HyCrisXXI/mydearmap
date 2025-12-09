// lib/features/auth/views/signup_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/auth/controllers/signup_view_model.dart';
import 'package:mydearmap/core/widgets/app_form_buttons.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignupView extends ConsumerStatefulWidget {
  const SignupView({super.key});

  @override
  ConsumerState<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends ConsumerState<SignupView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _birthDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final success = await ref.read(signupViewModelProvider.notifier).submit();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectBirthDate(SignupViewState state) async {
    final now = DateTime.now();
    final initialDate =
        state.birthDate ?? now.subtract(const Duration(days: 365 * 18));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      ref.read(signupViewModelProvider.notifier).onBirthDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SignupViewState>(signupViewModelProvider, (prev, next) {
      if (!mounted) return;

      // Sync controllers
      if (_nameController.text != next.form.name) {
        _nameController.value = TextEditingValue(
          text: next.form.name,
          selection: TextSelection.collapsed(offset: next.form.name.length),
        );
      }
      if (_emailController.text != next.form.email) {
        _emailController.value = TextEditingValue(
          text: next.form.email,
          selection: TextSelection.collapsed(offset: next.form.email.length),
        );
      }
      if (_passwordController.text != next.form.password) {
        _passwordController.value = TextEditingValue(
          text: next.form.password,
          selection: TextSelection.collapsed(offset: next.form.password.length),
        );
      }
      final numberText = next.form.number ?? '';
      if (_numberController.text != numberText) {
        _numberController.value = TextEditingValue(
          text: numberText,
          selection: TextSelection.collapsed(offset: numberText.length),
        );
      }
      if (_birthDateController.text != next.birthDateDisplay) {
        _birthDateController.value = TextEditingValue(
          text: next.birthDateDisplay,
          selection: TextSelection.collapsed(
            offset: next.birthDateDisplay.length,
          ),
        );
      }

      if (prev?.snackbarKey != next.snackbarKey &&
          next.snackbarMessage != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.snackbarMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(signupViewModelProvider.notifier).clearSnackbar();
      }
    });

    final signupState = ref.watch(signupViewModelProvider);
    final signupNotifier = ref.read(signupViewModelProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
          style: AppButtonStyles.circularIconButton,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(AppIcons.authBG, fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 60.0),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Text('Crear Cuenta', style: AppTextStyles.title),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre completo *',
                        errorText: signupState.nameError,
                      ),
                      onChanged: signupNotifier.onNameChanged,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email *',
                        errorText: signupState.emailError,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: signupNotifier.onEmailChanged,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña *',
                        errorText: signupState.passwordError,
                        suffixIcon: IconButton(
                          icon: Icon(
                            signupState.obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: signupNotifier.togglePasswordVisibility,
                        ),
                      ),
                      obscureText: signupState.obscurePassword,
                      onChanged: signupNotifier.onPasswordChanged,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _numberController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono (opcional)',
                        errorText: signupState.numberError,
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: signupNotifier.onNumberChanged,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _birthDateController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento (opcional) DD/MM/AAAA',
                        errorText: signupState.birthDateError,
                      ),
                      readOnly: true,
                      onTap: () => _selectBirthDate(signupState),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      key: ValueKey(signupState.form.gender),
                      initialValue: signupState.form.gender,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Género (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin especificar'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'male',
                          child: Text('Masculino'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'female',
                          child: Text('Femenino'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'other',
                          child: Text('Otro'),
                        ),
                      ],
                      onChanged: signupNotifier.onGenderChanged,
                    ),
                    const SizedBox(height: 60),
                    AppFormButtons(
                      primaryLabel: 'Registrarse',
                      onPrimaryPressed: signupState.canSubmit ? _signUp : null,
                      isProcessing: signupState.isSubmitting,
                      secondaryLabel: 'Iniciar Sesión',
                      onSecondaryPressed: signupState.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      secondaryIsCompact: false, // same width as primary
                      secondaryOutlined:
                          true, // outlined (transparent background + border)
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
