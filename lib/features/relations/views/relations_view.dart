import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/providers/relation_groups_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/relation_group.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/relations/views/relation_view.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart';
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
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Añadir vínculo'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RelationCreateView()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
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

  PreferredSizeWidget _buildRelationsAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: SvgPicture.asset(AppIcons.chevronLeft),
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: AppButtonStyles.circularIconButton,
      ),
      title: const Text('Vínculos'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: SvgPicture.asset(
              AppIcons.heartHandshake,
              colorFilter: const ColorFilter.mode(
                AppColors.blue,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: AppButtonStyles.circularIconButton,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: IconButton(
            icon: SvgPicture.asset(AppIcons.plus),
            onPressed: () => _showCreateOptions(context),
            style: AppButtonStyles.circularIconButton,
          ),
        ),
      ],
    );
  }

  Scaffold _buildShell(BuildContext context, Widget body) {
    return Scaffold(
      appBar: _buildRelationsAppBar(context),
      body: body,
    );
  }

  List<UserRelation> _applySearchFilter(List<UserRelation> relations) {
    if (_searchQuery.isEmpty) return relations;
    final query = _searchQuery.toLowerCase();
    return relations
        .where(
          (relation) => _relationDisplayName(relation)
              .toLowerCase()
              .contains(query),
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

  String _groupMembersLabel(RelationGroup group) {
    final count = group.members.length;
    if (count == 0) return 'Sin integrantes';
    if (count == 1) return '1 integrante';
    return '$count integrantes';
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, RelationGroup group) {
    final photoUrl = group.photoUrl?.trim();
    final trimmedName = group.name.trim();
    final displayLetter =
      trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RelationGroupDetailView(group: group),
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
              backgroundColor: photoUrl == null || photoUrl.isEmpty
                  ? Colors.white
                  : Colors.grey.shade300,
              backgroundImage:
                  photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Text(
                      displayLetter,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _groupMembersLabel(group),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Row(
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
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

    return InkWell(
      borderRadius: BorderRadius.circular(18),
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
              backgroundColor:
                  avatarUrl == null ? Colors.white : Colors.grey.shade300,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relationLabel,
                    style: Theme.of(context).textTheme.titleMedium,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => _buildShell(
        context,
        const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _buildShell(
        context,
        Center(child: Text('Error: $error')),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Inicia sesión para ver tus vínculos')),
          );
        }

        final relationsAsync = ref.watch(userRelationsProvider(user.id));
        final memoriesAsync = ref.watch(userMemoriesProvider);
        final groupsAsync = ref.watch(userRelationGroupsProvider(user.id));

        return relationsAsync.when(
          loading: () => _buildShell(
            context,
            const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _buildShell(
            context,
            Center(child: Text('Error: $error')),
          ),
          data: (relations) => memoriesAsync.when(
            loading: () => _buildShell(
              context,
              const Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _buildShell(
              context,
              Center(child: Text('Error: $error')),
            ),
            data: (memories) => groupsAsync.when(
              loading: () => _buildShell(
                context,
                const Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _buildShell(
                context,
                Center(child: Text('Error: $error')),
              ),
              data: (groups) {
                final sortedRelations = [...relations]
                  ..sort(
                    (a, b) =>
                        _relationDisplayName(a).compareTo(_relationDisplayName(b)),
                  );
                final filteredRelations = _applySearchFilter(sortedRelations);
                final filteredGroups = _applyGroupSearch(groups);
                final hasInitialItems =
                    sortedRelations.isNotEmpty || groups.isNotEmpty;
                final hasFilteredItems =
                    filteredRelations.isNotEmpty || filteredGroups.isNotEmpty;

                final tiles = <Widget>[];
                if (filteredGroups.isNotEmpty) {
                  tiles.add(_buildSectionHeader(context, 'Grupos'));
                  tiles.add(const SizedBox(height: 12));
                  for (final group in filteredGroups) {
                    tiles.add(_buildGroupCard(context, group));
                    tiles.add(const SizedBox(height: 12));
                  }
                }

                if (filteredRelations.isNotEmpty) {
                  tiles.add(_buildSectionHeader(context, 'Vínculos'));
                  tiles.add(const SizedBox(height: 12));
                  for (final relation in filteredRelations) {
                    tiles.add(
                      _buildRelationCard(
                        context: context,
                        relation: relation,
                        memories: memories,
                        currentUserId: user.id,
                      ),
                    );
                    tiles.add(const SizedBox(height: 12));
                  }
                }

                if (tiles.isNotEmpty) {
                  tiles.removeLast();
                }

                if (!hasInitialItems) {
                  return _buildShell(
                    context,
                    const Center(
                      child: Text('Aún no has creado vínculos ni grupos.'),
                    ),
                  );
                }

                return _buildShell(
                  context,
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar vínculos o grupos',
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(bottom: 0),
                              child: const Icon(Icons.search),
                            ),
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
                        child: hasFilteredItems
                            ? ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                children: tiles,
                              )
                            : const Center(
                                child: Text('No se encontraron resultados.'),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
  return '$count recuerdos';
}
