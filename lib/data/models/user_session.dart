// lib/data/models/user_session.dart
import 'user.dart';
import 'memory.dart';
import 'wishlist.dart';
import 'playlist.dart';
import 'user_relation.dart';
import 'user_stats.dart';

class UserSession {
  User user;
  List<Memory> memories;
  List<Wishlist> wishlists;
  List<Playlist> playlists;
  List<UserRelation> relations;
  UserStats? stats;
  DateTime lastUpdated;

  UserSession({
    required this.user,
    List<Memory>? memories,
    List<Wishlist>? wishlists,
    List<Playlist>? playlists,
    List<UserRelation>? relations,
    this.stats,
  }) : memories = memories ?? [],
       wishlists = wishlists ?? [],
       playlists = playlists ?? [],
       relations = relations ?? [],
       lastUpdated = DateTime.now();

  void updateMemories(List<Memory> newMemories) {
    memories = newMemories;
    lastUpdated = DateTime.now();
  }

  void updateWishlists(List<Wishlist> newWishlists) {
    wishlists = newWishlists;
    lastUpdated = DateTime.now();
  }

  void updatePlaylists(List<Playlist> newPlaylists) {
    playlists = newPlaylists;
    lastUpdated = DateTime.now();
  }

  void updateRelations(List<UserRelation> newRelations) {
    relations = newRelations;
    lastUpdated = DateTime.now();
  }

  void updateStats(UserStats newStats) {
    stats = newStats;
    lastUpdated = DateTime.now();
  }

  void clearSession() {
    memories.clear();
    wishlists.clear();
    playlists.clear();
    relations.clear();
    stats = null;
  }

  void updateUserProfile(User updatedUser) {
    user = updatedUser;
    lastUpdated = DateTime.now();
  }
}
