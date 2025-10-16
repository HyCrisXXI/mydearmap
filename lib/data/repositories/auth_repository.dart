// lib/data/repositories/auth_repository.dart
import '../models/user.dart';

abstract class AuthRepository {
  Stream<User?> get currentUser;

  Future<void> signUpWithPassword(String email, String password);
  Future<void> signInWithPassword(String email, String password);

  Future<bool> isNewUser(String userId);
  Future<void> createUserProfile(String userId, String email);
  Future<void> signOut();
}
