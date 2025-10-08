import 'user_stats.dart';
import 'memory.dart';
import 'playlist.dart';
import 'wishlist.dart';
import 'user_relation.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String passwordHash;
  final String? number;
  final DateTime? birthDate;
  final Gender gender;
  final String? profileUrl;
  final DateTime createdAt;

  UserStats? stats;
  List<Memory> memories = [];
  List<Playlist> playlists = [];
  List<Wishlist> wishlists = [];
  List<UserRelation> relations = [];

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.number,
    this.birthDate,
    required this.gender,
    this.profileUrl,
    required this.createdAt,
  });
}

enum Gender { male, female, other }
