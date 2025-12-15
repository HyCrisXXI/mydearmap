import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/providers/group_memories_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/providers/relation_groups_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/relation_group.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/relations/views/relation_view.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart';
import 'package:mydearmap/features/relations/controllers/relation_group_controller.dart';
import 'package:mydearmap/features/relations/views/relation_create_view.dart';
import 'package:mydearmap/features/relations/views/relation_group_create_view.dart';
import 'package:mydearmap/features/relations/views/relation_group_detail_view.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RelationsView extends ConsumerStatefulWidget {
  const RelationsView({super.key});

  @override
  ConsumerState<RelationsView> createState() => _RelationsViewState();
}

class _RelationsViewState extends ConsumerState<RelationsView> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (nextQuery == _searchQuery) return;
    setState(() => _searchQuery = nextQuery);
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: SvgPicture.asset(AppIcons.userRound),
                title: const Text('Añadir vínculo'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RelationCreateView(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: SvgPicture.asset(AppIcons.usersRound),
                title: const Text('Crear grupo'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RelationGroupCreateView(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<UserRelation> _applySearchFilter(List<UserRelation> relations) {
    if (_searchQuery.isEmpty) return relations;
    final query = _searchQuery.toLowerCase();
    return relations
        .where(
          (relation) =>
              _relationDisplayName(relation).toLowerCase().contains(query),
        )
        .toList();
  }

  List<RelationGroup> _applyGroupSearch(List<RelationGroup> groups) {
    if (_searchQuery.isEmpty) return groups;
    final query = _searchQuery.toLowerCase();
    return groups
        .where((group) => group.name.toLowerCase().contains(query))
        .toList();
  }

  String _groupMemoriesLabel(int count) {
    if (count == 0) return 'Sin recuerdos';
    if (count == 1) return '1 recuerdo';
    return '$count recuerdos';
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    WidgetRef ref,
    RelationGroup group,
    String currentUserId,
  ) {
    final photoUrl = buildGroupPhotoUrl(group.photoUrl);
    final trimmedName = group.name.trim();
    final displayLetter = trimmedName.isNotEmpty
        ? trimmedName[0].toUpperCase()
        : '?';
    final memoriesAsync = ref.watch(groupMemoriesProvider(group.id));

    return _RelationListCard(
      title: group.name,
      subtitle: memoriesAsync.when(
        loading: () => const Text('Cargando recuerdos...'),
        error: (error, _) => const Text('Error al cargar recuerdos'),
        data: (memories) => Text(_groupMemoriesLabel(memories.length)),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RelationGroupDetailView(group: group),
          ),
        );
      },
      onLongPress: () =>
          _confirmDeleteGroup(context, ref, group, currentUserId),
      photoUrl: photoUrl,
      displayLetter: displayLetter,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppIcons.usersRound,
            height: 22,
            colorFilter: const ColorFilter.mode(
              AppColors.blue,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            group.members.length.toString(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteGroup(
    BuildContext context,
    WidgetRef ref,
    RelationGroup group,
    String currentUserId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar grupo'),
        content: Text(
          '¿Seguro que deseas eliminar "${group.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final controller = ref.read(relationGroupControllerProvider.notifier);
    try {
      await controller.deleteGroup(
        groupId: group.id,
        currentUserId: currentUserId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo eliminado correctamente.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el grupo: $error')),
      );
    }
  }

  Widget _buildRelationCard({
    required BuildContext context,
    required UserRelation relation,
    required List<Memory> memories,
    required String currentUserId,
  }) {
    final shared = sharedMemoriesForRelation(
      allMemories: memories,
      currentUserId: currentUserId,
      relatedUserId: relation.relatedUser.id,
    );
    final relationLabel = _relationDisplayName(relation);
    final avatarUrl = buildAvatarUrl(relation.relatedUser.profileUrl);

    return _RelationListCard(
      title: relationLabel,
      subtitle: Text(_sharedMemoriesLabel(shared.length)),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RelationDetailView(
              currentUserId: currentUserId,
              relatedUserId: relation.relatedUser.id,
            ),
          ),
        );
      },
      photoUrl: avatarUrl,
      displayLetter: relationLabel.isNotEmpty
          ? relationLabel[0].toUpperCase()
          : '?',
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const _RelationsLayout(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          _RelationsLayout(child: Center(child: Text('Error: $error'))),
      data: (user) {
        if (user == null) {
          return const _RelationsLayout(
            child: Center(child: Text('Inicia sesión para ver tus vínculos')),
          );
        }

        final relationsAsync = ref.watch(userRelationsProvider(user.id));
        final memoriesAsync = ref.watch(userMemoriesProvider);
        final groupsAsync = ref.watch(userRelationGroupsProvider(user.id));

        return relationsAsync.when(
          loading: () => const _RelationsLayout(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) =>
              _RelationsLayout(child: Center(child: Text('Error: $error'))),
          data: (relations) => memoriesAsync.when(
            loading: () => const _RelationsLayout(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) =>
                _RelationsLayout(child: Center(child: Text('Error: $error'))),
            data: (memories) {
              final sorted = [...relations]
                ..sort(
                  (a, b) => _relationDisplayName(
                    a,
                  ).compareTo(_relationDisplayName(b)),
                );

              final filtered = _applySearchFilter(sorted);

              return _RelationsLayout(
                onAddPressed: () => _showCreateOptions(context),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar vínculos o grupos',
                          suffixIcon: SvgPicture.asset(AppIcons.search),
                          suffixIconConstraints: const BoxConstraints(
                            minHeight: 24,
                            minWidth: 40,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                        ),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                    Expanded(
                      child: groupsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) =>
                            Center(child: Text('Error: $error')),
                        data: (groups) {
                          final sortedGroups = [...groups]
                            ..sort(
                              (a, b) => a.name.toLowerCase().compareTo(
                                b.name.toLowerCase(),
                              ),
                            );
                          final filteredGroups = _applyGroupSearch(
                            sortedGroups,
                          );
                          final hasRelations = filtered.isNotEmpty;
                          final hasGroups = filteredGroups.isNotEmpty;

                          if (!hasRelations && !hasGroups) {
                            final message = _searchQuery.isEmpty
                                ? 'Aún no has creado vínculos ni grupos.'
                                : 'No se encontraron resultados.';
                            return Center(child: Text(message));
                          }

                          return ListView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            children: [
                              if (hasGroups) ...[
                                _buildSectionHeader(context, 'Grupos'),
                                const SizedBox(height: 10),
                                for (
                                  var i = 0;
                                  i < filteredGroups.length;
                                  i++
                                ) ...[
                                  _buildGroupCard(
                                    context,
                                    ref,
                                    filteredGroups[i],
                                    user.id,
                                  ),
                                  if (i < filteredGroups.length - 1)
                                    const SizedBox(height: 10),
                                ],
                                if (hasRelations) const SizedBox(height: 24),
                              ],
                              if (hasRelations) ...[
                                _buildSectionHeader(context, 'Vínculos'),
                                const SizedBox(height: 10),
                                for (var i = 0; i < filtered.length; i++) ...[
                                  _buildRelationCard(
                                    context: context,
                                    relation: filtered[i],
                                    memories: memories,
                                    currentUserId: user.id,
                                  ),
                                  if (i < filtered.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RelationsLayout extends StatelessWidget {
  const _RelationsLayout({required this.child, this.onAddPressed});

  final Widget child;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.upperPadding,
                bottom: 8.0,
                left: 16,
                right: 30.0,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: SvgPicture.asset(AppIcons.chevronLeft),
                      onPressed: () => Navigator.of(context).pop(),
                      style: AppButtonStyles.circularIconButton,
                    ),
                  ),
                  const Text('Vínculos', style: AppTextStyles.title),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: SvgPicture.asset(
                            AppIcons.heartHandshake,
                            colorFilter: const ColorFilter.mode(
                              AppColors.blue,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          style: AppButtonStyles.circularIconButton,
                        ),
                        if (onAddPressed != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: SvgPicture.asset(AppIcons.plus),
                            onPressed: onAddPressed,
                            style: AppButtonStyles.circularIconButton,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
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
  return '$count recuerdos';
}

class _RelationListCard extends StatelessWidget {
  const _RelationListCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.photoUrl,
    this.displayLetter = '?',
    this.onLongPress,
    this.trailing,
  });

  final String title;
  final Widget subtitle;
  final VoidCallback onTap;
  final String? photoUrl;
  final String displayLetter;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: Colors.white,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: photoUrl == null || photoUrl!.isEmpty
                  ? Colors.white
                  : Colors.grey.shade300,
              backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null || photoUrl!.isEmpty
                  ? Text(
                      displayLetter,
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                    child: subtitle,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
