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
import 'package:mydearmap/features/memories/widgets/memory_selection_widget.dart';

import 'package:mydearmap/features/relations/views/group_form_view.dart';
import 'package:mydearmap/core/providers/relation_groups_provider.dart';

class RelationGroupDetailView extends ConsumerStatefulWidget {
  const RelationGroupDetailView({super.key, required this.group});

  final RelationGroup group;

  @override
  ConsumerState<RelationGroupDetailView> createState() =>
      _RelationGroupDetailViewState();
}

class _RelationGroupDetailViewState
    extends ConsumerState<RelationGroupDetailView> {
  Future<void> _handleLinkExistingMemory() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sesión para añadir recuerdos al grupo.'),
        ),
      );
      return;
    }

    final userMemories = await ref.read(userMemoriesProvider.future);
    if (!mounted) return;

    final currentGroupMemories = await ref.read(
      groupMemoriesProvider(widget.group.id).future,
    );
    if (!mounted) return;

    final selectedMemories = await Navigator.of(context).push<List<Memory>>(
      MaterialPageRoute(
        builder: (_) => MemorySelectionWidget(
          availableMemories: userMemories,
          selectedMemories: currentGroupMemories,
          onSelectionDone: (selected) {
            Navigator.of(context).pop(selected);
          },
        ),
      ),
    );

    if (selectedMemories == null || selectedMemories.isEmpty) return;

    final controller = ref.read(memoryControllerProvider.notifier);
    int successCount = 0;

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Añadiendo recuerdos...')));

    for (final memory in selectedMemories) {
      try {
        await controller.linkMemoryToGroup(
          groupId: widget.group.id,
          memoryId: memory.id!,
          addedBy: currentUser.id,
        );
        successCount++;
      } catch (e) {
        // Ignore errors for individual items or log them
      }
    }

    ref.invalidate(groupMemoriesProvider(widget.group.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$successCount recuerdos añadidos al grupo.')),
    );
  }

  void _navigateToEditGroup(RelationGroup group) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RelationGroupCreateView(initialGroup: group),
      ),
    );

    if (result == true) {
      // Refresh logic handled by provider invalidation in CreateView
    }
  }

  Future<void> _showMembersSheet(List<User> members) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = members[index];
                        return ListTile(
                          leading: _SimpleAvatar(user: user, size: 40),
                          title: Text(
                            user.name.isNotEmpty ? user.name : user.email,
                          ),
                          // subtitle: Text(user.email), // Optional
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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

  @override
  Widget build(BuildContext context) {
    // Re-watch the groups provider to get the updated group data
    final groupsAsync = ref.watch(
      userRelationGroupsProvider(
        ref.watch(currentUserProvider).value?.id ?? '',
      ),
    );

    // Try to find the current group in the list, otherwise use the passed widget.group
    // This allows the UI to update automatically when the provider refreshes.
    final currentGroup = groupsAsync.maybeWhen(
      data: (groups) => groups.firstWhere(
        (g) => g.id == widget.group.id,
        orElse: () => widget.group,
      ),
      orElse: () => widget.group,
    );

    final photoUrl = buildGroupPhotoUrl(currentGroup.photoUrl);
    final members = currentGroup.members;
    // Removed unused currentUserAsync

    final memoriesAsync = ref.watch(groupMemoriesProvider(widget.group.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.upperPadding,
                    left: 20,
                    right: 20,
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(AppIcons.chevronLeft),
                        onPressed: () => Navigator.of(context).pop(),
                        style: AppButtonStyles.circularIconButton,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          currentGroup.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: SvgPicture.asset(AppIcons.plus),
                            onPressed: _handleLinkExistingMemory,
                            style: AppButtonStyles.circularIconButton,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: SvgPicture.asset(AppIcons.pencil),
                            onPressed: () => _navigateToEditGroup(currentGroup),
                            style: AppButtonStyles.circularIconButton,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    children: [
                      const SizedBox(height: 12),

                      Center(
                        child: GestureDetector(
                          onTap: () => _showFullImage(context, photoUrl),
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
                              backgroundColor:
                                  photoUrl == null || photoUrl.isEmpty
                                  ? Colors.grey.shade200
                                  : Colors.transparent,
                              backgroundImage:
                                  photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: (photoUrl == null || photoUrl.isEmpty
                                  ? Text(
                                      currentGroup.name.isNotEmpty
                                          ? currentGroup.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        color: Colors.black,
                                      ),
                                    )
                                  : null),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Recuerdos del grupo',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (members.isNotEmpty)
                              _RelationsParticipantsHeader(
                                members: members,
                                onTap: () => _showMembersSheet(members),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      memoriesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) =>
                            Text('No se pudieron cargar los recuerdos: $error'),
                        data: (memories) {
                          if (memories.isEmpty) {
                            return const Text(
                              'Aún no hay recuerdos en este grupo.',
                            );
                          }

                          return MemoriesGrid(
                            memories: memories,
                            physics: const NeverScrollableScrollPhysics(),
                            gridPadding: EdgeInsets.zero,
                            showFavoriteOverlay: false,
                            onMemoryTap: (memory) {
                              final memoryId = memory.id;
                              if (memoryId == null) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MemoryDetailView(memoryId: memoryId),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationsParticipantsHeader extends StatelessWidget {
  const _RelationsParticipantsHeader({required this.members, this.onTap});

  final List<User> members;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Adapter to reuse logic if possible, or reimplement similar to MemoryView
    if (members.isEmpty) {
      return const SizedBox(width: 48); // Balance back button
    }

    final preview = members.take(2).toList(growable: false);
    const avatarSize = 36.0; // Smaller for header
    const overlap = 16.0;
    final stackWidth = avatarSize + (preview.length - 1) * overlap;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: stackWidth,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (preview.length > 1)
                  Positioned(
                    left: overlap,
                    child: _SimpleAvatar(user: preview[1], size: avatarSize),
                  ),
                Positioned(
                  left: 0,
                  child: _SimpleAvatar(user: preview[0], size: avatarSize),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppIcons.usersRound,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(
                  AppColors.accentColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                members.length.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleAvatar extends StatelessWidget {
  const _SimpleAvatar({required this.user, this.size = 40});

  final User user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = buildAvatarUrl(user.profileUrl);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        color: Colors.grey.shade200,
        image: avatarUrl != null
            ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
            : null,
      ),
      child: avatarUrl == null
          ? Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
