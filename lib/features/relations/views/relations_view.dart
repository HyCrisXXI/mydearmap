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
                    MaterialPageRoute(
                      builder: (_) => const RelationCreateView(),
                    ),
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
  ) {
    final photoUrl = group.photoUrl?.trim();
    final trimmedName = group.name.trim();
    final displayLetter = trimmedName.isNotEmpty
        ? trimmedName[0].toUpperCase()
        : '?';
    final memoriesAsync = ref.watch(groupMemoriesProvider(group.id));

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
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Text(
                      displayLetter,
                      style: const TextStyle(fontSize: 20, color: Colors.black),
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
                  memoriesAsync.when(
                    loading: () => Text(
                      'Cargando recuerdos...',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                    error: (error, _) => Text(
                      'Error al cargar recuerdos',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                    ),
                    data: (memories) => Text(
                      _groupMemoriesLabel(memories.length),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                      style: const TextStyle(fontSize: 20, color: Colors.black),
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
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
                child: sorted.isEmpty
                    ? const Center(child: Text('Aún no has creado vinculos.'))
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar vínculos',
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
                            child: filtered.isEmpty
                                ? const Center(
                                    child: Text('No se encontraron vínculos.'),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    itemBuilder: (context, index) {
                                      final relation = filtered[index];
                                      final shared = sharedMemoriesForRelation(
                                        allMemories: memories,
                                        currentUserId: user.id,
                                        relatedUserId: relation.relatedUser.id,
                                      );
                                      final relationLabel =
                                          _relationDisplayName(relation);

                                      // Avatar del usuario relacionado
                                      final avatarUrl = buildAvatarUrl(
                                        relation.relatedUser.profileUrl,
                                      );

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RelationDetailView(
                                                    currentUserId: user.id,
                                                    relatedUserId:
                                                        relation.relatedUser.id,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            color: Colors.grey.shade100,
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor:
                                                    avatarUrl == null
                                                    ? Colors.white
                                                    : Colors.grey.shade300,
                                                backgroundImage:
                                                    avatarUrl != null
                                                    ? NetworkImage(avatarUrl)
                                                    : null,
                                                child: avatarUrl == null
                                                    ? Text(
                                                        (relationLabel
                                                                .isNotEmpty
                                                            ? relationLabel[0]
                                                                  .toUpperCase()
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
                                                      _sharedMemoriesLabel(
                                                        shared.length,
                                                      ),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color:
                                                                Colors.black54,
                                                          ),
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
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 12),
                                    itemCount: filtered.length,
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
