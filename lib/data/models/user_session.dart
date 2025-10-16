import 'user.dart';
import 'memory.dart';
import 'wishlist.dart';
import 'playlist.dart';

class UserSession {
  final User user;
  List<Memory> memories;
  List<Wishlist> wishlists;
  List<Playlist> playlists;
  DateTime lastUpdated;

  UserSession({
    required this.user,
    List<Memory>? memories,
    List<Wishlist>? wishlists,
    List<Playlist>? playlists,
  }) : memories = memories ?? [],
       wishlists = wishlists ?? [],
       playlists = playlists ?? [],
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

  void clearSession() {
    memories.clear();
    wishlists.clear();
    playlists.clear();
  }
}
