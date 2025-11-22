// lib/features/profile/views/profile_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/achievement_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/features/profile/views/profile_form_view.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/features/auth/controllers/auth_controller.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Center(child: Text('Error al cargar el perfil: $error')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Usuario no autenticado')),
          );
        }

        final achievementsAsync = ref.watch(userAchievementsProvider(user.id));

        final avatarUrl = buildAvatarUrl(user.profileUrl);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi perfil'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar perfil',
                onPressed: () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => ProfileEditView(user: user),
                    ),
                  );
                  if (updated == true) {
                    Future.microtask(() => ref.invalidate(currentUserProvider));
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primaryColor,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            color: Color.fromARGB(255, 17, 17, 17),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: AppSizes.paddingLarge),
                const Divider(),
                const SizedBox(height: AppSizes.paddingMedium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Logros desbloqueados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingMedium),
                achievementsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (error, _) => Text(
                    'Error al cargar los logros: $error',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  data: (achievements) {
                    if (achievements.isEmpty) {
                      return const Text(
                        'Todavía no has desbloqueado ningún logro.',
                        style: TextStyle(color: Colors.black54),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: achievements.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSizes.paddingSmall),
                      itemBuilder: (context, index) {
                        final userAchievement = achievements[index];
                        final achievement = userAchievement.achievement;

                        return Card(
                          child: ListTile(
                            leading: achievement?.iconUrl != null
                                ? Image.network(
                                    achievement!.iconUrl!,
                                    width: 48,
                                    height: 48,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.emoji_events,
                                      size: 48,
                                      color: Colors.amber,
                                    ),
                                  )
                                : const Icon(
                                    Icons.emoji_events,
                                    size: 48,
                                    color: Colors.amber,
                                  ),
                            title: Text(
                              achievement?.name ?? 'Logro',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              achievement?.description ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _formatDate(userAchievement.unlockedAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLarge,
                  vertical: AppSizes.paddingLarge,
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _handleLogout(context, ref),
                ),
              ),
              AppNavBar(
                currentIndex: 4, // El índice del perfíl
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        if (context.mounted) Navigator.of(context).pop(); // cerrar drawer
        await ref.read(authControllerProvider.notifier).signOut();
        ref.invalidate(
          currentUserProvider,
        ); // Invalidate to clear cached user data
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
