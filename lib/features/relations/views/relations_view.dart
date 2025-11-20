import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/memories/views/memories_view.dart';
import 'package:mydearmap/features/timecapsules/views/timecapsules_view.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/features/relations/views/relation_view.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart';
import 'package:mydearmap/features/relations/views/relation_create_view.dart';

class RelationsView extends ConsumerWidget {
  const RelationsView({super.key});

  PreferredSizeWidget _buildRelationsAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Image.asset(AppIcons.chevronLeft),
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MemoriesView()),
            (route) => false,
          );
        },
        style: AppButtonStyles.circularIconButton,
      ),
      title: const Text('Tus vínculos'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Image.asset(AppIcons.timer),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimeCapsulesView()),
              );
            },
            style: AppButtonStyles.circularIconButton,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Image.asset(AppIcons.heartHandshake, color: AppColors.blue),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MemoriesView()),
                (route) => false,
              );
            },
            style: AppButtonStyles.circularIconButton,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: IconButton(
            icon: Image.asset(AppIcons.plus),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RelationCreateView()),
              );
            },
            style: AppButtonStyles.circularIconButton,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => Scaffold(
        appBar: _buildRelationsAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: _buildRelationsAppBar(context),
        body: Center(child: Text('Error: $error')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Inicia sesión para ver tus vínculos')),
          );
        }

        final relationsAsync = ref.watch(userRelationsProvider(user.id));
        final memoriesAsync = ref.watch(userMemoriesProvider);

        return relationsAsync.when(
          loading: () => Scaffold(
            appBar: _buildRelationsAppBar(context),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: _buildRelationsAppBar(context),
            body: Center(child: Text('Error: $error')),
          ),
          data: (relations) => memoriesAsync.when(
            loading: () => Scaffold(
              appBar: _buildRelationsAppBar(context),
              body: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Scaffold(
              appBar: _buildRelationsAppBar(context),
              body: Center(child: Text('Error: $error')),
            ),
            data: (memories) {
              final sorted = [...relations]
                ..sort(
                  (a, b) => _relationDisplayName(
                    a,
                  ).compareTo(_relationDisplayName(b)),
                );

              return Scaffold(
                appBar: _buildRelationsAppBar(context),
                body: sorted.isEmpty
                    ? const Center(child: Text('Aún no has creado vinculos.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        itemBuilder: (context, index) {
                          final relation = sorted[index];
                          final shared = sharedMemoriesForRelation(
                            allMemories: memories,
                            currentUserId: user.id,
                            relatedUserId: relation.relatedUser.id,
                          );
                          final relationLabel = _relationDisplayName(relation);

                          // Avatar del usuario relacionado
                          final avatarUrl = buildAvatarUrl(
                            relation.relatedUser.profileUrl,
                          );

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RelationDetailView(
                                    currentUserId: user.id,
                                    relatedUserId: relation.relatedUser.id,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.grey.shade100,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: avatarUrl == null
                                        ? Colors.white
                                        : Colors.grey.shade300,
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? Text(
                                            (relationLabel.isNotEmpty
                                                ? relationLabel[0].toUpperCase()
                                                : '?'),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.black,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          relationLabel,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _sharedMemoriesLabel(shared.length),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemCount: sorted.length,
                      ),
                bottomNavigationBar: AppNavBar(currentIndex: 1),
              );
            },
          ),
        );
      },
    );
  }
}

String _relationDisplayName(UserRelation relation) {
  final name = relation.relatedUser.name.trim();
  if (name.isNotEmpty) return name;
  final email = relation.relatedUser.email.trim();
  if (email.isNotEmpty) return email;
  return '';
}

String _sharedMemoriesLabel(int count) {
  return '$count recuerdos en común';
}
