import '../models/user.dart';

abstract class AuthRepository {
  Stream<User?> get currentUser;
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String token);
  Future<void> signOut();
  Future<bool> isNewUser(String userId);
  Future<void> createUserProfile(User user);
}
