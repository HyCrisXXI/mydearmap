// lib/core/widgets/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/map/views/map_view.dart';
import '../../features/auth/views/login_view.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        return user != null ? const MapView() : const LoginView();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) {
        return const LoginView();
      },
    );
  }
}
