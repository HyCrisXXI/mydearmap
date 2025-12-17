import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/achievement_provider.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';

class AchievementsBottomSheet extends ConsumerWidget {
  const AchievementsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSizes.paddingMedium,
            right: AppSizes.paddingMedium,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Flexible(
                child: userAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                  data: (user) {
                    if (user == null) {
                      return const Center(child: Text('Usuario no encontrado'));
                    }
                    final achievementsAsync = ref.watch(
                      userAchievementsProvider(user.id),
                    );

                    return achievementsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      error: (error, _) => Text(
                        'Error al cargar los logros: $error',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      data: (achievements) {
                        if (achievements.isEmpty) {
                          return const Center(
                            child: Text(
                              'Todavía no has desbloqueado ningún logro.',
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: achievements.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSizes.paddingSmall),
                          itemBuilder: (context, index) {
                            final userAchievement = achievements[index];
                            final achievement = userAchievement.achievement;
                            final iconAsset =
                                achievement?.localIconAsset ?? AppIcons.star;

                            return Card(
                              elevation: 0,
                              color: Colors.transparent,
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 54,
                                  height: 54,
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: SvgPicture.asset(
                                    iconAsset,
                                    fit: BoxFit.contain,
                                  ),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
