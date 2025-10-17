// lib/core/utils/form_cache.dart
class FormErrorCache {
  static final Map<String, String> _lastFailedAttempts = {};

  static bool isRepeatedError(String email, String password, String error) {
    final key = '$email-$password';
    return _lastFailedAttempts[key] == error;
  }

  static void cacheFailedAttempt(String email, String password, String error) {
    final key = '$email-$password';
    _lastFailedAttempts[key] = error;
  }

  static void clearCache() {
    _lastFailedAttempts.clear();
  }
}
