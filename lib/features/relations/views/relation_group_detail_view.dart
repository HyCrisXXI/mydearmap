import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/group_memories_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/relation_group.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/features/memories/views/memory_form_view.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/memories/widgets/memories_grid.dart';

class RelationGroupDetailView extends ConsumerWidget {
  const RelationGroupDetailView({super.key, required this.group});

  final RelationGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoUrl = group.photoUrl?.trim();
    final members = group.members;
    final memoriesAsync = ref.watch(groupMemoriesProvider(group.id));

    Future<void> handleCreateMemory() async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemoryUpsertView.create(initialGroup: group),
        ),
      );
      ref.invalidate(groupMemoriesProvider(group.id));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(AppIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
          style: AppButtonStyles.circularIconButton,
        ),
        title: const Text('Detalle del grupo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 56,
              backgroundColor: photoUrl == null || photoUrl.isEmpty
                  ? Colors.grey.shade200
                  : Colors.grey.shade300,
              backgroundImage:
                  photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Text(
                      group.name.isNotEmpty
                          ? group.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.black,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            group.name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _groupMembersCopy(members.length),
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: handleCreateMemory,
            icon: const Icon(Icons.add),
            label: const Text('Añadir recuerdo'),
          ),
          const SizedBox(height: 32),
          Text(
            'Recuerdos del grupo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          memoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('No se pudieron cargar los recuerdos: $error'),
            data: (memories) {
              if (memories.isEmpty) {
                return const Text('Aún no hay recuerdos en este grupo.');
              }
              final preview = memories.length > 8
                  ? memories.take(8).toList()
                  : memories;
              return MemoriesGrid(
                memories: preview,
                physics: const NeverScrollableScrollPhysics(),
                gridPadding: EdgeInsets.zero,
                onMemoryTap: (memory) {
                  final memoryId = memory.id;
                  if (memoryId == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MemoryDetailView(memoryId: memoryId),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Integrantes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            const Text('Aún no hay integrantes en este grupo.')
          else
            ...members.map((user) => _GroupMemberTile(user: user)),
        ],
      ),
    );
  }
}

class _GroupMemberTile extends StatelessWidget {
  const _GroupMemberTile({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = buildAvatarUrl(user.profileUrl);
    final displayName = user.name.trim().isNotEmpty ? user.name : user.email;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              avatarUrl == null ? Colors.white : Colors.grey.shade300,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  displayName.trim().isNotEmpty
                      ? displayName.trim()[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.black),
                )
              : null,
        ),
        title: Text(displayName),
      ),
    );
  }
}

String _groupMembersCopy(int count) {
  if (count == 0) return 'Sin integrantes';
  if (count == 1) return '1 integrante';
  return '$count integrantes';
}
