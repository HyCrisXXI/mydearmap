import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState.initial());

  // Inicia el proceso de login/registro enviando el código OTP al email
  Future<void> signInWithOtp(String email) async {
    state = const AuthState.loading();

    try {
      await _authRepository.signInWithOtp(email);
      state = AuthState.otpSent(email: email);
    } catch (e) {
      state = AuthState.error(e.toString());
      rethrow;
    }
  }

  // Verifica el código OTP que el usuario introduce
  Future<void> verifyOtp(String email, String token) async {
    state = const AuthState.loading();

    try {
      await _authRepository.verifyOtp(email, token);
      state = const AuthState.authenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
      rethrow;
    }
  }

  // Cierra la sesión
  Future<void> signOut() async {
    state = const AuthState.loading();

    try {
      await _authRepository.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
      rethrow;
    }
  }

  // Resetea el estado de error
  void clearError() {
    if (state is AuthError) {
      state = const AuthState.initial();
    }
  }
}

// Estados de la autenticación
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthOtpSent extends AuthState {
  final String email;

  const AuthOtpSent({required this.email});
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

// Extension methods para facilitar el uso de los estados
extension AuthStateExtension on AuthState {
  bool get isInitial => this is AuthInitial;
  bool get isLoading => this is AuthLoading;
  bool get isOtpSent => this is AuthOtpSent;
  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isUnauthenticated => this is AuthUnauthenticated;
  bool get isError => this is AuthError;

  String? get email => isOtpSent ? (this as AuthOtpSent).email : null;
  String? get errorMessage => isError ? (this as AuthError).message : null;
}
