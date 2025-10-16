// lib/features/auth/views/signup_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../controllers/signup_controller.dart';
import '../../../core/utils/validators.dart';

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

  String? _emailError;
  String? _passwordError;
  String? _nameError;
  String? _numberError;
  String? _birthDateError;

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
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

  void _loadSavedData() {
    final formState = ref.read(signupFormProvider);

    _emailController.text = formState.email;
    _passwordController.text = formState.password;
    _nameController.text = formState.name;
    _numberController.text = formState.number ?? '';
    _birthDateController.text = formState.birthDate ?? '';
    _selectedGender = formState.gender;

    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);
    _validateName(_nameController.text);
    _validatenumber(_numberController.text);
    _validateBirthDate(_birthDateController.text);
  }

  void _saveFormData() {
    final notifier = ref.read(signupFormProvider.notifier);
    notifier.updateEmail(_emailController.text);
    notifier.updatePassword(_passwordController.text);
    notifier.updateName(_nameController.text);
    notifier.updateNumber(
      _numberController.text.isEmpty ? null : _numberController.text,
    );
    notifier.updateBirthDate(
      _birthDateController.text.isEmpty ? null : _birthDateController.text,
    );
    notifier.updateGender(_selectedGender);
  }

  void _validateEmail(String value) =>
      setState(() => _emailError = Validators.emailValidator(value));
  void _validatePassword(String value) =>
      setState(() => _passwordError = Validators.passwordValidator(value));
  void _validateName(String value) =>
      setState(() => _nameError = Validators.nameValidator(value));
  void _validatenumber(String value) =>
      setState(() => _numberError = Validators.numberValidator(value));
  void _validateBirthDate(String value) =>
      setState(() => _birthDateError = Validators.birthDateValidator(value));

  bool get _isFormValid {
    return _emailError == null &&
        _passwordError == null &&
        _nameError == null &&
        _numberError == null &&
        _birthDateError == null &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _nameController.text.isNotEmpty;
  }

  Future<void> _signUp() async {
    if (!_isFormValid) return;

    // Crear el estado del formulario directamente desde los controladores
    final formData = SignupFormState(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      number: _numberController.text.isEmpty ? null : _numberController.text,
      birthDate: _birthDateController.text.isEmpty
          ? null
          : _birthDateController.text,
      gender: _selectedGender,
    );

    final authControllerNotifier = ref.read(authControllerProvider.notifier);

    try {
      await authControllerNotifier.signUp(formData);

      if (mounted) {
        ref.read(signupFormProvider.notifier).clear();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _birthDateController.text =
          "${picked.day}/${picked.month}/${picked.year}";
      _validateBirthDate(_birthDateController.text);
      _saveFormData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _saveFormData();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                errorText: _nameError,
              ),
              onChanged: (value) {
                _validateName(value);
                _saveFormData();
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email *',
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
                errorText: _emailError,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                _validateEmail(value);
                _saveFormData();
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña *',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                errorText: _passwordError,
              ),
              obscureText: true,
              onChanged: (value) {
                _validatePassword(value);
                _saveFormData();
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _numberController,
              decoration: InputDecoration(
                labelText: 'Teléfono (opcional)',
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
                errorText: _numberError,
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                _validatenumber(value);
                _saveFormData();
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _birthDateController,
              decoration: InputDecoration(
                labelText: 'Fecha de nacimiento (opcional) DD/MM/AAAA',
                prefixIcon: const Icon(Icons.calendar_today),
                border: const OutlineInputBorder(),
                errorText: _birthDateError,
              ),
              readOnly: true,
              onTap: _selectBirthDate,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Género (opcional)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('— Sin especificar —'),
                ),
                DropdownMenuItem(value: 'male', child: Text('Masculino')),
                DropdownMenuItem(value: 'female', child: Text('Femenino')),
                DropdownMenuItem(value: 'other', child: Text('Otro')),
              ],
              onChanged: (String? value) {
                setState(() {
                  _selectedGender = value;
                });
                _saveFormData();
              },
            ),
            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isFormValid && !isLoading ? _signUp : null,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrarse'),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('¿Ya tienes cuenta?'),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Iniciar Sesión'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
