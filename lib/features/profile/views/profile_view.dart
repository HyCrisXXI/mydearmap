// lib/features/profile/views/profile_view.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/achievement_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/features/profile/views/profile_form_view.dart';
import 'package:mydearmap/features/auth/controllers/auth_controller.dart';
import 'package:mydearmap/features/wishlist/views/wishlist_view.dart';
import 'package:mydearmap/features/profile/widgets/achievements_bottom_sheet.dart';
import 'package:mydearmap/core/widgets/pulse_button.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
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
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              // 1. Background Image
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppIcons.profileBG),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // 2. Safe Area Wrapper for Content
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    // 3. Custom Header with Padding
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSizes.upperPadding,
                        bottom: 8.0,
                      ),
                      child: Center(
                        child: Text('Perfil', style: AppTextStyles.title),
                      ),
                    ),
                    // 4. Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: Column(
                          children: [
                            const SizedBox(height: AppSizes.paddingSmall),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _showFullImage(context, avatarUrl),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: CircleAvatar(
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
                                                color: Color.fromARGB(
                                                  255,
                                                  17,
                                                  17,
                                                  17,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Transform.translate(
                                    offset: const Offset(5, 5),
                                    child: PulseButton(
                                      child: IconButton(
                                        style:
                                            AppButtonStyles.circularIconButton,
                                        onPressed: () => _navigateToEditProfile(
                                          context,
                                          ref,
                                          user,
                                        ),
                                        icon: SvgPicture.asset(AppIcons.pencil),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.paddingMedium),
                            Card(
                              color: Colors.transparent,
                              elevation: 0,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Cuenta',
                                  style: AppTextStyles.textField,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name,
                                                style: AppTextStyles.textButton,
                                              ),
                                              Text(
                                                user.email,
                                                style: AppTextStyles.textButton,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SvgPicture.asset(AppIcons.chevronRight),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () =>
                                    _navigateToEditProfile(context, ref, user),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Card(
                              color: Colors.transparent,
                              elevation: 0,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Wishlist',
                                  style: AppTextStyles.textField,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Todos los lugares o planes que\nestás deseando hacer.',
                                            style: AppTextStyles.textButton,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SvgPicture.asset(AppIcons.chevronRight),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  showDialog<void>(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (_) => const WishlistDialog(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 36),
                            Card(
                              color: Colors.transparent,
                              elevation: 0,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Logros',
                                  style: AppTextStyles.textField,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: achievementsAsync.when(
                                            loading: () => const Center(
                                              child:
                                                  CircularProgressIndicator.adaptive(),
                                            ),
                                            error: (error, _) => Text(
                                              'Error: $error',
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                            data: (achievements) {
                                              if (achievements.isEmpty) {
                                                return const Text(
                                                  'Todavía no has desbloqueado ningún logro.',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                  ),
                                                );
                                              }
                                              // Take max 5 icons for preview
                                              final previewAchievements =
                                                  achievements.take(5).toList();

                                              return Wrap(
                                                spacing: 12.0,
                                                runSpacing: 8.0,
                                                children: previewAchievements.map((
                                                  userAchievement,
                                                ) {
                                                  final achievement =
                                                      userAchievement
                                                          .achievement;
                                                  final iconAsset =
                                                      achievement
                                                          ?.localIconAsset ??
                                                      AppIcons.star;

                                                  return Container(
                                                    width:
                                                        54, // Made bigger as requested
                                                    height: 54,
                                                    padding:
                                                        const EdgeInsets.all(
                                                          10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .primaryColor,
                                                      shape: BoxShape.circle,
                                                      // Mimicking circularIconButton: no border, no shadow by default in that style
                                                    ),
                                                    child: SvgPicture.asset(
                                                      iconAsset,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  );
                                                }).toList(),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SvgPicture.asset(AppIcons.chevronRight),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    showDragHandle: true,
                                    builder: (_) =>
                                        const AchievementsBottomSheet(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSizes.paddingLarge),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.paddingLarge,
                                vertical: AppSizes.paddingLarge,
                              ),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textColor,
                                  backgroundColor: Colors.transparent,
                                  side: const BorderSide(
                                    color: AppColors.buttonBackground,
                                    width: 1.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.borderRadius,
                                    ),
                                  ),
                                  fixedSize: const Size(200, 35),
                                ),
                                onPressed: () => _handleLogout(context, ref),
                                child: const Text('Cerrar sesión'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(500),
          child: Image.network(imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProfileEditView(user: user)),
    );
    if (updated == true) {
      Future.microtask(() => ref.invalidate(currentUserProvider));
    }
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
