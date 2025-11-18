import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/core/widgets/memory_card.dart';
import 'package:mydearmap/core/constants/constants.dart';

class RelationsView extends ConsumerWidget {
  const RelationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
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
            appBar: AppBar(title: const Text('Tus vínculos')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('Tus vínculos')),
            body: Center(child: Text('Error: $error')),
          ),
          data: (relations) => memoriesAsync.when(
            loading: () => Scaffold(
              appBar: AppBar(title: const Text('Tus vínculos')),
              body: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Scaffold(
              appBar: AppBar(title: const Text('Tus vínculos')),
              body: Center(child: Text('Error: $error')),
            ),
            data: (memories) {
              final sorted = [...relations]
                ..sort(
                  (a, b) =>
                      _relationListLabel(a).compareTo(_relationListLabel(b)),
                );

              return Scaffold(
                appBar: AppBar(title: const Text('Tus vínculos')),
                body: sorted.isEmpty
                    ? const Center(child: Text('Aún no has creado relaciones.'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        itemBuilder: (context, index) {
                          final relation = sorted[index];
                          final shared = _sharedMemoriesForRelation(
                            allMemories: memories,
                            currentUserId: user.id,
                            relatedUserId: relation.relatedUser.id,
                          );
                          final relationLabel = _relationListLabel(relation);

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
              );
            },
          ),
        );
      },
    );
  }
}

class RelationDetailView extends ConsumerStatefulWidget {
  const RelationDetailView({
    super.key,
    required this.currentUserId,
    required this.relatedUserId,
  });

  final String currentUserId;
  final String relatedUserId;

  @override
  ConsumerState<RelationDetailView> createState() => _RelationDetailViewState();
}

class _RelationDetailViewState extends ConsumerState<RelationDetailView> {
  // Eliminado: lógica de actualización de color

  @override
  Widget build(BuildContext context) {
    final relationsAsync = ref.watch(
      userRelationsProvider(widget.currentUserId),
    );
    final memoriesAsync = ref.watch(userMemoriesProvider);

    return relationsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (relations) {
        final relation = _findRelationByUser(relations, widget.relatedUserId);
        if (relation == null) {
          return const Scaffold(
            body: Center(child: Text('Relación no encontrada')),
          );
        }

        return memoriesAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) =>
              Scaffold(body: Center(child: Text('Error: $error'))),
          data: (memories) {
            final shared = _sharedMemoriesForRelation(
              allMemories: memories,
              currentUserId: widget.currentUserId,
              relatedUserId: relation.relatedUser.id,
            );

            // Placeholder: favorito si el título contiene 'fav'
            final sortedShared = [...shared]
              ..sort((a, b) {
                final aFav = a.title.toLowerCase().contains('fav');
                final bFav = b.title.toLowerCase().contains('fav');
                if (aFav == bFav) {
                  return b.happenedAt.compareTo(a.happenedAt);
                }
                return bFav ? 1 : -1; // Favoritos arriba
              });

            final previewCount = sortedShared.length > 8
                ? 8
                : sortedShared.length;
            // Mostrar nombre de la relación o nombre real
            final displayName = (relation.relationType.trim().isNotEmpty)
                ? relation.relationType.trim()
                : relation.relatedUser.name.trim();
            final Widget sharedContent = sortedShared.isEmpty
                ? const Text('Aún no hay recuerdos en común.')
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: previewCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: AppCardMemory.aspectRatio,
                        ),
                    itemBuilder: (_, index) {
                      final memory = sortedShared[index];
                      final mainMedia = memory.media.isNotEmpty
                          ? memory.media.first
                          : null;
                      final imageUrl =
                          mainMedia != null && mainMedia.url != null
                          ? buildMediaPublicUrl(mainMedia.url)
                          : null;
                      // Placeholder: favorito si el título contiene 'fav'
                      final isFavorite = memory.title.toLowerCase().contains(
                        'fav',
                      );
                      return MemoryCard(
                        memory: memory,
                        imageUrl: imageUrl,
                        overlay: Positioned(
                          top: 10,
                          right: 10,
                          child: Image.asset(
                            isFavorite ? AppIcons.starFilled : AppIcons.star,
                            width: 23,
                            height: 22,
                          ),
                        ),
                      );
                    },
                  );

            // Construir URL de avatar
            final avatarUrl = buildAvatarUrl(relation.relatedUser.profileUrl);

            return Scaffold(
              appBar: AppBar(
                title: Text(displayName),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {},
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: avatarUrl == null
                              ? Colors.white
                              : Colors.grey.shade300,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Text(
                                  (displayName.isNotEmpty
                                      ? displayName[0].toUpperCase()
                                      : '?'),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.black,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _sharedMemoriesLabel(sortedShared.length),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Recuerdos en común',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    sharedContent,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

UserRelation? _findRelationByUser(
  List<UserRelation> relations,
  String relatedUserId,
) {
  for (final relation in relations) {
    if (relation.relatedUser.id == relatedUserId) return relation;
  }
  return null;
}

List<Memory> _sharedMemoriesForRelation({
  required Iterable<Memory> allMemories,
  required String currentUserId,
  required String relatedUserId,
}) {
  final result = <Memory>[];

  for (final memory in allMemories) {
    if (memory.participants.isEmpty) continue;

    UserRole? currentParticipant;
    UserRole? relatedParticipant;

    for (final participant in memory.participants) {
      if (participant.user.id == currentUserId) {
        currentParticipant = participant;
      } else if (participant.user.id == relatedUserId) {
        relatedParticipant = participant;
      }
    }

    if (currentParticipant == null || relatedParticipant == null) continue;
    if (currentParticipant.role == MemoryRole.guest ||
        relatedParticipant.role == MemoryRole.guest) {
      continue;
    }

    result.add(memory);
  }

  result.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
  return result;
}

String _relationDisplayName(UserRelation relation) {
  final name = relation.relatedUser.name.trim();
  if (name.isNotEmpty) return name;
  final email = relation.relatedUser.email.trim();
  if (email.isNotEmpty) return email;
  return relation.relationType;
}

String _relationListLabel(UserRelation relation) {
  final relationName = relation.relationType.trim();
  if (relationName.isNotEmpty) return relationName;
  return _relationDisplayName(relation);
}

String _sharedMemoriesLabel(int count) {
  if (count == 1) return '1 recuerdo en común';
  return '$count recuerdos en común';
}
