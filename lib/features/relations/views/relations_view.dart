import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/features/relations/views/relation_view.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart';
import 'package:mydearmap/features/relations/views/relation_create_view.dart';
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

  @override
  Widget build(BuildContext context) {
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

              final filtered = _applySearchFilter(sorted);

              return Scaffold(
                appBar: _buildRelationsAppBar(context),
                body: sorted.isEmpty
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
                                    separatorBuilder: (_, __) =>
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
