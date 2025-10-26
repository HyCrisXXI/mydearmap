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
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: (map['id'] ?? map['user_id'] ?? '').toString(),
      name: (map['name'] ?? map['full_name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      number: (map['number'] ?? map['phone']) as String?,
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'].toString())
          : (map['birthDate'] != null
              ? DateTime.tryParse(map['birthDate'].toString())
              : null),
      gender: map['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.toString().split('.').last == map['gender'].toString(),
              orElse: () => Gender.other,
            )
          : Gender.other,
      profileUrl: (map['profile_url'] ?? map['profileUrl'] ?? map['avatar_url']) as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : (map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }
}

enum Gender { male, female, other }
