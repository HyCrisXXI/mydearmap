import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/widgets/memories_grid.dart';
import 'package:mydearmap/data/models/playlist.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/models/memory.dart';

// Puedes adaptar esto a tu sistema de providers/repositorios reales
class PlaylistView extends ConsumerWidget {
  final Playlist playlist;
  final List<User> users; // Usuarios añadidos a la playlist
  final List<Memory> memories; // Recuerdos de la playlist

  const PlaylistView({
    super.key,
    required this.playlist,
    required this.users,
    required this.memories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name, style: AppTextStyles.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_PlaylistUsersAvatars(users: users)],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist.description != null &&
                playlist.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  playlist.description!,
                  style: AppTextStyles.subtitle,
                ),
              ),
            Expanded(
              child: MemoriesGrid(
                memories: memories,
                showFavoriteOverlay: false,
                // ...puedes pasar otros parámetros si lo necesitas
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistUsersAvatars extends StatelessWidget {
  final List<User> users;
  static const int maxAvatars = 3;

  const _PlaylistUsersAvatars({required this.users});

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.take(maxAvatars).toList();
    final extraCount = users.length - visibleUsers.length;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, top: 10.0),
      child: SizedBox(
        height: AppSizes.profileAvatarSize,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            for (int i = 0; i < visibleUsers.length; i++)
              Positioned(
                right: i * 22.0,
                child: Container(
                  width: AppSizes.profileAvatarSize,
                  height: AppSizes.profileAvatarSize,
                  decoration: AppDecorations.profileAvatar(
                    visibleUsers[i].profileUrl != null &&
                            visibleUsers[i].profileUrl!.isNotEmpty
                        ? NetworkImage(visibleUsers[i].profileUrl!)
                        : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                  ),
                ),
              ),
            if (extraCount > 0)
              Positioned(
                right: visibleUsers.length * 22.0,
                child: Container(
                  width: AppSizes.profileAvatarSize,
                  height: AppSizes.profileAvatarSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.buttonDisabledBackground,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people,
                          size: 18,
                          color: AppColors.textColor,
                        ),
                        Text(
                          '+$extraCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
