import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/achievement_provider.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';

class AchievementsDialog extends ConsumerWidget {
  const AchievementsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Logros desbloqueados',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: achievements.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSizes.paddingSmall),
                          itemBuilder: (context, index) {
                            final userAchievement = achievements[index];
                            final achievement = userAchievement.achievement;

                            return Card(
                              elevation: 0,
                              color: Colors.transparent,
                              margin: EdgeInsets.zero,
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
