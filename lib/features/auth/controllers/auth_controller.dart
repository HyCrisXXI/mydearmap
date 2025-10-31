// lib/features/auth/controllers/auth_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'package:mydearmap/data/repositories/auth_repository.dart';
import 'package:mydearmap/core/errors/auth_errors.dart';
import 'package:mydearmap/core/utils/validators.dart';
import 'package:mydearmap/features/auth/models/signup_form_state.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  AuthRepository get _authRepository => ref.read(authRepositoryProvider);

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
      final trimmedEmail = form.email.trim();
      final trimmedPassword = form.password.trim();

      _validateBeforeSend(trimmedEmail, trimmedPassword);

      final userId = await _authRepository.signUpWithPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      final profileData = {
        'id': userId,
        'name': form.name.trim(),
        'email': trimmedEmail,
        'number': form.number,
        'birth_date': form.birthDate,
        'gender': form.gender ?? 'other',
      };

      await _authRepository.createUserProfile(profileData);
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
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      _validateBeforeSend(trimmedEmail, trimmedPassword);
      await _authRepository.signInWithPassword(
        email: trimmedEmail,
        password: trimmedPassword,
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
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}
