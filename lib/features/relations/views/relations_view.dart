import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart';

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
                          final color = _colorFromHex(
                            _extractColorHex(relation),
                          );
                          final relationLabel = _relationListLabel(relation);

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
                                color: color.withValues(alpha: 0.1),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: color,
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
  bool _updatingColor = false;

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
            final previewCount = shared.length > 8 ? 8 : shared.length;
            final colorHex = _extractColorHex(relation);
            final color = _colorFromHex(colorHex);
            final displayName = _relationDisplayName(relation);
            final Widget sharedContent = shared.isEmpty
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
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (_, index) {
                      final memory = shared[index];
                      return _MemoryPreviewCard(memory: memory);
                    },
                  );

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
                        Tooltip(
                          message: 'Toca el círculo para elegir un color',
                          child: GestureDetector(
                            onTap: _updatingColor
                                ? null
                                : () => _pickColor(context, relation),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: _updatingColor
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
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
                                relation.relationType,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _sharedMemoriesLabel(shared.length),
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

  Future<void> _pickColor(BuildContext context, UserRelation relation) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => const _ColorPickerSheet(),
    );

    if (selected == null) return;
    if (_extractColorHex(relation)?.toUpperCase() == selected.toUpperCase()) {
      return;
    }

    setState(() => _updatingColor = true);
    try {
      await ref
          .read(relationControllerProvider.notifier)
          .updateRelationColor(
            currentUserId: widget.currentUserId,
            relatedUserId: relation.relatedUser.id,
            colorHex: selected,
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el color: $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingColor = false);
    }
  }
}

class _ColorPickerSheet extends StatelessWidget {
  const _ColorPickerSheet();

  static const List<String> _palette = [
    '#FF6F61',
    '#FF9F1C',
    '#F9C74F',
    '#90BE6D',
    '#43AA8B',
    '#577590',
    '#6C5CE7',
    '#B185DB',
    '#F28482',
    '#14B8A6',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Elige un color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _palette
                  .map(
                    (hex) => GestureDetector(
                      onTap: () => Navigator.of(context).pop(hex),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _colorFromHex(hex),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryPreviewCard extends StatelessWidget {
  const _MemoryPreviewCard({required this.memory});

  final Memory memory;

  @override
  Widget build(BuildContext context) {
    final coverUrl = _resolveCoverUrl(memory);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl != null)
                    Image.network(coverUrl, fit: BoxFit.cover)
                  else
                    Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.black45,
                        size: 36,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: 10,
              ),
              child: Text(
                memory.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
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

String? _extractColorHex(UserRelation relation) {
  final dynamic dyn = relation;
  try {
    final value = dyn.color;
    if (value is String && value.isNotEmpty) return value;
  } catch (_) {}
  try {
    final value = dyn.colorHex;
    if (value is String && value.isNotEmpty) return value;
  } catch (_) {}
  return null;
}

Color _colorFromHex(String? hex) {
  final sanitized = (hex ?? '').replaceFirst('#', '').toUpperCase();
  final value = int.tryParse(sanitized, radix: 16);
  if (value == null) {
    return const Color(0xFF7C9EB2);
  }
  return Color(0xFF000000 | value);
}

String? _resolveCoverUrl(Memory memory) {
  for (final media in memory.media) {
    if (media.type == MediaType.image) {
      return buildMediaPublicUrl(media.url);
    }
  }
  return null;
}
