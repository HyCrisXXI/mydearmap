import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/controllers/auth_controller.dart';

// Proveedor para el repositorio de autenticación
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// Proveedor que expone el estado actual del usuario (Stream desde Supabase)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

// Proveedor para el controlador de autenticación (StateNotifier)
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);

// Proveedor para verificar si el usuario está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value != null;
});

// Proveedor para obtener el usuario actual
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});
