// lib/data/models/wishlist.dart
import 'user.dart';

class Wishlist {
  Wishlist({
    required this.id,
    required this.title,
    required this.completed,
    required this.user,
  });

  final String id;
  final String title;
  final bool completed;
  final User user;

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'] ?? json['creator'];
    final user = _parseUser(rawUser, json);
    return Wishlist(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      completed: json['completed'] == true,
      user: user,
    );
  }

  static User _parseUser(dynamic rawUser, Map<String, dynamic> fallbackJson) {
    if (rawUser is Map<String, dynamic>) {
      return User.fromJson(rawUser);
    }

    return User(
      id: (fallbackJson['user_id'] ?? '').toString(),
      name: (fallbackJson['user_name'] ?? 'Usuario').toString(),
      email: (fallbackJson['user_email'] ?? 'sin-correo@mydearmap.app')
          .toString(),
      number: null,
      birthDate: null,
      gender: Gender.other,
      profileUrl: null,
      createdAt: DateTime.now(),
    );
  }
}
