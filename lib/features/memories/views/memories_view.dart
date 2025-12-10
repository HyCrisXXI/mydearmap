// lib/features/memories/views/memories_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/memories/widgets/memories_grid.dart';
import 'package:mydearmap/features/relations/views/relations_view.dart';
import 'package:mydearmap/features/timeline/view/timeline_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/memories/views/create_join_memory.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/features/memories/models/memory_filters.dart';

class MemoriesView extends ConsumerStatefulWidget {
  const MemoriesView({super.key});

  @override
  ConsumerState<MemoriesView> createState() => _MemoriesViewState();
}

class _MemoriesViewState extends ConsumerState<MemoriesView> {
  MemoryFilterCriteria _filters = MemoryFilterCriteria.empty;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(userMemoriesProvider));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openFiltersSheet(List<Memory> memories) async {
    if (memories.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aún no hay recuerdos para filtrar.')),
      );
      return;
    }
    final currentUser = ref.read(currentUserProvider).value;
    var relations = <UserRelation>[];
    if (currentUser != null) {
      relations = await ref.read(userRelationsProvider(currentUser.id).future);
    }
    if (!mounted) return;
    final userOptions = MemoryFilterUtils.buildUserOptions(
      memories: memories,
      currentUser: currentUser,
      relations: relations,
    );
    final updated = await showMemoryFiltersSheet(
      context: context,
      initialCriteria: _filters,
      userOptions: userOptions,
    );
    if (!mounted || updated == null) return;
    setState(() {
      _filters = updated;
    });
  }

  void _clearFilters() {
    if (!_filters.hasFilters) return;
    setState(() => _filters = MemoryFilterCriteria.empty);
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(userMemoriesProvider);

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
                left: 16, // Typical padding
                right: 30.0, // Right padding for actions
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text('Recuerdos', style: AppTextStyles.title),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.timeline),
                        tooltip: 'Ver timeline',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MemoriesTimelineView(),
                            ),
                          );
                        },
                        style: AppButtonStyles.circularIconButton,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: SvgPicture.asset(AppIcons.heartHandshake),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RelationsView(),
                            ),
                          );
                        },
                        style: AppButtonStyles.circularIconButton,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: SvgPicture.asset(AppIcons.plus),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreateJoinMemoryView(),
                            ),
                          );
                        },
                        style: AppButtonStyles.circularIconButton,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: memoriesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (error, _) => Center(
                  child: Text('No se pudieron cargar los recuerdos: $error'),
                ),
                data: (memories) {
                  if (memories.isEmpty) {
                    return const Center(
                      child: Text('Todavía no has guardado ningún recuerdo.'),
                    );
                  }

                  final filtered = MemoryFilterUtils.applyFilters(
                    memories,
                    _filters,
                  );
                  if (filtered.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No hay recuerdos que coincidan con los filtros.',
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Limpiar filtros'),
                        ),
                      ],
                    );
                  }

                  return MemoriesGrid(
                    memories: filtered,
                    showFeatured: true,
                    onFilterTap: () => _openFiltersSheet(memories),
                    filtersActive: _filters.hasFilters,
                    onMemoryTap: (memory) {
                      final memoryId = memory.id ?? '';
                      if (memoryId.isEmpty) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MemoryDetailView(memoryId: memoryId),
                        ),
                      );
                    },
                    gridPadding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingLarge,
                      AppSizes.paddingLarge,
                      AppSizes.paddingLarge,
                      80,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
