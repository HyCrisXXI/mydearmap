// lib/features/auth/controllers/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/user_session.dart';
import '../../../data/repositories/session_repository.dart';
import 'signup_controller.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) {
    return event.session?.user;
  });
});

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(Supabase.instance.client);
});

class UserSessionNotifier extends Notifier<UserSession?> {
  @override
  UserSession? build() {
    return null;
  }

  void setSession(UserSession session) {
    state = session;
  }

  void clearSession() {
    state = null;
  }
}

final userSessionProvider = NotifierProvider<UserSessionNotifier, UserSession?>(
  UserSessionNotifier.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  SupabaseClient get _supabaseClient => Supabase.instance.client;

  Future<void> signUp(SignupFormState form) async {
    state = const AsyncValue.loading();

    try {
      print("Contraseña a enviar: '${form.password}'");
      final AuthResponse response = await _supabaseClient.auth.signUp(
        email: form.email.trim(),
        password: form.password.trim(),
      );

      final user = response.user;

      if (user == null) {
        throw Exception("Registro fallido: usuario no retornado.");
      }

      final profileData = {
        'id': user.id,
        'name': form.name.trim(),
        'email': form.email.trim(),
        'number': form.number?.isEmpty ?? true ? null : form.number,
        'birth_date': form.birthDate?.isEmpty ?? true ? null : form.birthDate,
        'gender': form.gender?.isEmpty ?? true ? 'other' : form.gender,
      };

      await _supabaseClient.from('users').insert(profileData);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      state = const AsyncValue.data(null);
    } on AuthException catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      throw Exception(e.message);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      throw Exception('Error desconocido al iniciar sesión: $e');
    }
  }

  Future<void> signOut() async {
    ref.read(userSessionProvider.notifier).clearSession();
    await _supabaseClient.auth.signOut();
  }
}
