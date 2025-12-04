import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart';
import 'package:mydearmap/core/widgets/memories_grid.dart';

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
  @override
  void initState() {
    super.initState();
    // Fuerza recarga de recuerdos solo al entrar a la pantalla de detalle
    Future.microtask(() => ref.invalidate(userMemoriesProvider));
  }

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
        final relation = findRelationByUser(relations, widget.relatedUserId);
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
            final shared = sharedMemoriesForRelation(
              allMemories: memories,
              currentUserId: widget.currentUserId,
              relatedUserId: relation.relatedUser.id,
            );

            // Ordena favoritos primero, luego por fecha
            final sortedShared = [...shared]
              ..sort((a, b) {
                final aFav = a.isFavorite;
                final bFav = b.isFavorite;
                if (aFav == bFav) {
                  return b.happenedAt.compareTo(a.happenedAt);
                }
                return bFav ? 1 : -1; // Favoritos arriba
              });

            final previewCount = sortedShared.length > 8
                ? 8
                : sortedShared.length;
            final displayName = relation.relatedUser.name.trim().isNotEmpty
                ? relation.relatedUser.name.trim()
                : relation.relatedUser.email.trim();

            final Widget sharedContent = sortedShared.isEmpty
                ? const Text('Aún no hay recuerdos en común.')
                : MemoriesGrid(
                    memories: sortedShared.take(previewCount).toList(),
                    onMemoryTap: (memory) {
                      // Puedes navegar a detalle si lo deseas
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    gridPadding: EdgeInsets.zero, // o el padding que desees
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
                                sharedMemoriesLabel(sortedShared.length),
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
