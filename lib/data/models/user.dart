// lib/data/models/user.dart

class User {
  final String id;
  final String name;
  final String email;
  final String? number;
  final DateTime? birthDate;
  final Gender gender;
  final String? profileUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.number,
    this.birthDate,
    required this.gender,
    this.profileUrl,
    required this.createdAt,
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
    };
  }
}

enum Gender { male, female, other }
