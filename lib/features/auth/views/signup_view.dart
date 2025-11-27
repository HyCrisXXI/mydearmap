// lib/features/auth/views/signup_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/auth/controllers/signup_view_model.dart';
import 'package:mydearmap/core/widgets/app_form_buttons.dart';

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

  void _syncControllers(SignupViewState state) {
    if (_nameController.text != state.form.name) {
      _nameController.value = TextEditingValue(
        text: state.form.name,
        selection: TextSelection.collapsed(offset: state.form.name.length),
      );
    }

    if (_emailController.text != state.form.email) {
      _emailController.value = TextEditingValue(
        text: state.form.email,
        selection: TextSelection.collapsed(offset: state.form.email.length),
      );
    }

    if (_passwordController.text != state.form.password) {
      _passwordController.value = TextEditingValue(
        text: state.form.password,
        selection: TextSelection.collapsed(offset: state.form.password.length),
      );
    }

    final numberText = state.form.number ?? '';
    if (_numberController.text != numberText) {
      _numberController.value = TextEditingValue(
        text: numberText,
        selection: TextSelection.collapsed(offset: numberText.length),
      );
    }

    if (_birthDateController.text != state.birthDateDisplay) {
      _birthDateController.value = TextEditingValue(
        text: state.birthDateDisplay,
        selection: TextSelection.collapsed(
          offset: state.birthDateDisplay.length,
        ),
      );
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

    _syncControllers(signupState);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(AppIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
          style: AppButtonStyles.circularIconButton,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 60.0),
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
              decoration: const InputDecoration(labelText: 'Género (opcional)'),
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
                DropdownMenuItem<String?>(value: 'other', child: Text('Otro')),
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
    );
  }
}
