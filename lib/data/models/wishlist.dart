import 'user.dart';

class Wishlist {
  final int id;
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
}

class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint(this.latitude, this.longitude);
}
