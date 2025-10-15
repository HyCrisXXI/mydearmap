import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).clearError();
    });
  }

  Future<void> _sendOtp() async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithOtp(_emailController.text.trim());
    } catch (e) {
      // El error ya está manejado en el state
    }
  }

  Future<void> _verifyOtp() async {
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(_emailController.text.trim(), _otpController.text.trim());
    } catch (e) {
      // El error ya está manejado en el state
    }
  }

  void _clearError() {
    ref.read(authControllerProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Mostrar errores
            if (authState.isError) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(authState.errorMessage!)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _clearError,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              readOnly: authState.isOtpSent || authState.isLoading,
              onChanged: (_) => _clearError(),
            ),

            if (authState.isOtpSent) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'Código de 6 dígitos',
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (_) => _clearError(),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authState.isLoading
                    ? null
                    : authState.isOtpSent
                    ? _verifyOtp
                    : _sendOtp,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        authState.isOtpSent
                            ? 'Verificar Código'
                            : 'Enviar Código',
                      ),
              ),
            ),

            if (authState.isOtpSent) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: authState.isLoading ? null : _sendOtp,
                child: const Text('Reenviar código'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
