// lib/data/models/wishlist.dart
import 'user.dart';

class Wishlist {
  final String id;
  final String title;
  final String? description;
  final GeoPoint location;
  final DateTime createdAt;

  User creator;
  List<User> sharedWith = [];

  Wishlist({
    required this.id,
    required this.title,
    this.description,
    required this.location,
    required this.createdAt,
    required this.creator,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: GeoPoint.fromJson(json['location']),
      createdAt: DateTime.parse(json['created_at'] as String),
      creator: User.fromJson(json['creator']),
    );
  }
}

class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint(this.latitude, this.longitude);

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as List;
    return GeoPoint(coordinates[1] as double, coordinates[0] as double);
  }
}
