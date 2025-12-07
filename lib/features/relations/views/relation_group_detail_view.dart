import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/group_memories_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/relation_group.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/features/memories/controllers/memory_controller.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/memories/widgets/memories_grid.dart';

class RelationGroupDetailView extends ConsumerWidget {
  const RelationGroupDetailView({super.key, required this.group});

  final RelationGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoUrl = group.photoUrl?.trim();
    final members = group.members;
    final currentUserAsync = ref.watch(currentUserProvider);
    final memoriesAsync = ref.watch(groupMemoriesProvider(group.id));

    Future<void> handleLinkExistingMemory() async {
      final currentUser = currentUserAsync.value;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicia sesión para añadir recuerdos al grupo.'),
          ),
        );
        return;
      }

      final selectedMemory = await showModalBottomSheet<Memory>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => const _ExistingMemoryPickerSheet(),
      );

      if (selectedMemory == null || !context.mounted) return;
      final memoryId = selectedMemory.id;
      if (memoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El recuerdo seleccionado no se puede vincular.'),
          ),
        );
        return;
      }

      final controller = ref.read(memoryControllerProvider.notifier);
      try {
        await controller.linkMemoryToGroup(
          groupId: group.id,
          memoryId: memoryId,
          addedBy: currentUser.id,
        );
        ref.invalidate(groupMemoriesProvider(group.id));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recuerdo añadido al grupo.')),
        );
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo añadir el recuerdo: $error')),
        );
      }
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
            onPressed: handleLinkExistingMemory,
            icon: const Icon(Icons.library_add),
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
                showFavoriteOverlay: false,
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

class _ExistingMemoryPickerSheet extends ConsumerWidget {
  const _ExistingMemoryPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(userMemoriesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selecciona un recuerdo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: memoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('No se pudieron cargar los recuerdos: $error'),
                  ),
                  data: (memories) {
                    if (memories.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aún no has creado recuerdos. Hazlo desde la sección principal y vuelve aquí para añadirlos.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: memories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final memory = memories[index];
                        final description = memory.description?.trim();
                        final subtitleParts = <String>[_formatMemoryDate(memory.happenedAt)];
                        if (description != null && description.isNotEmpty) {
                          subtitleParts.add(description);
                        }

                        return ListTile(
                          tileColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          title: Text(memory.title),
                          subtitle: Text(subtitleParts.join(' · ')),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pop(memory),
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
}

String _groupMembersCopy(int count) {
  if (count == 0) return 'Sin integrantes';
  if (count == 1) return '1 integrante';
  return '$count integrantes';
}

String _formatMemoryDate(DateTime rawDate) {
  final date = rawDate.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}
