// lib/features/auth/controllers/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/auth_errors.dart';
import '../../../core/utils/validators.dart';
import '../models/signup_form_state.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  SupabaseClient get _supabaseClient => Supabase.instance.client;

  void _validateBeforeSend(String email, String password) {
    final emailError = Validators.emailValidator(email);
    if (emailError != null) {
      throw AppAuthException.invalidEmail();
    }

    final passwordError = Validators.passwordValidator(password);
    if (passwordError != null) {
      throw AppAuthException.weakPassword();
    }
  }

  Future<void> signUp(SignupFormState form) async {
    state = const AsyncValue.loading();

    try {
      _validateBeforeSend(form.email, form.password);

      final AuthResponse response = await _supabaseClient.auth.signUp(
        email: form.email.trim(),
        password: form.password.trim(),
      );

      if (response.user == null) {
        throw AppAuthException("Error al crear la cuenta");
      }

      final profileData = {
        'id': response.user!.id,
        'name': form.name.trim(),
        'email': form.email.trim(),
        'number': form.number,
        'birth_date': form.birthDate,
        'gender': form.gender ?? 'other',
      };

      await _supabaseClient.from('users').insert(profileData);
      state = const AsyncValue.data(null);
    } on AuthException catch (e) {
      final appAuthException = AppAuthException.fromSupabase(e);
      state = AsyncValue.error(appAuthException, StackTrace.current);
      throw appAuthException;
    } catch (e) {
      if (e.toString().contains('socket') || e.toString().contains('network')) {
        final networkException = AppAuthException.networkError();
        state = AsyncValue.error(networkException, StackTrace.current);
        throw networkException;
      }
      if (e is AppAuthException) {
        state = AsyncValue.error(e, StackTrace.current);
        rethrow;
      }
      final genericException = AppAuthException('Error inesperado: $e');
      state = AsyncValue.error(genericException, StackTrace.current);
      throw genericException;
    }
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      _validateBeforeSend(email, password);
      await _supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      state = const AsyncValue.data(null);
    } on AuthException catch (e) {
      final appAuthException = AppAuthException.fromSupabase(e);
      state = AsyncValue.error(appAuthException, StackTrace.current);
      throw appAuthException;
    } catch (e) {
      if (e.toString().contains('socket') || e.toString().contains('network')) {
        final networkException = AppAuthException.networkError();
        state = AsyncValue.error(networkException, StackTrace.current);
        throw networkException;
      }
      if (e is AppAuthException) {
        state = AsyncValue.error(e, StackTrace.current);
        rethrow;
      }
      final genericException = AppAuthException('Error inesperado: $e');
      state = AsyncValue.error(genericException, StackTrace.current);
      throw genericException;
    }
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
    state = const AsyncValue.data(null);
  }
}
