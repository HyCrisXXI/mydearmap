// lib/data/models/user.dart
import 'user_stats.dart';
import 'memory.dart';
import 'playlist.dart';
import 'wishlist.dart';
import 'user_relation.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? number;
  final DateTime? birthDate;
  final Gender gender;
  final String? profileUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserStats? stats;
  List<Memory> memories = [];
  List<Playlist> playlists = [];
  List<Wishlist> wishlists = [];
  List<UserRelation> relations = [];

  User({
    required this.id,
    required this.name,
    required this.email,
    this.number,
    this.birthDate,
    required this.gender,
    this.profileUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      number: json['number'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      gender: Gender.values.firstWhere(
        (e) => e.toString().split('.').last == json['gender'],
        orElse: () => Gender.other,
      ),
      profileUrl: json['profile_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'number': number,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender.name,
      'profile_url': profileUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum Gender { male, female, other }
