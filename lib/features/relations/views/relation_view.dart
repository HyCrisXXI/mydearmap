import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart';
import 'package:mydearmap/features/memories/widgets/memories_grid.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/widgets/pulse_button.dart';

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
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Error: $error')),
      ),
      data: (relations) {
        final relation = findRelationByUser(relations, widget.relatedUserId);
        if (relation == null) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text('Relación no encontrada')),
          );
        }

        return memoriesAsync.when(
          loading: () => const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: Text('Error: $error')),
          ),
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
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Aún no hay recuerdos en común.'),
                  )
                : MemoriesGrid(
                    memories: sortedShared.take(previewCount).toList(),
                    onMemoryTap: (memory) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MemoryDetailView(memoryId: memory.id!),
                        ),
                      );
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    gridPadding: EdgeInsets.zero,
                  );

            // Construir URL de avatar
            final avatarUrl = buildAvatarUrl(relation.relatedUser.profileUrl);

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSizes.upperPadding,
                        left: 16,
                        right: 16,
                        bottom: 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PulseButton(
                            child: IconButton(
                              icon: SvgPicture.asset(AppIcons.chevronLeft),
                              onPressed: () => Navigator.of(context).pop(),
                              style: AppButtonStyles.circularIconButton,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontFamily: 'TikTokSans',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                      height: 1.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    sharedMemoriesLabel(sortedShared.length),
                                    style: const TextStyle(
                                      fontFamily: 'TikTokSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textGray,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 14,
                                left: 20,
                                right: 16,
                              ),
                              child: GestureDetector(
                                onTap: () => _showFullImage(context, avatarUrl),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryColor,
                                      width: 1.0,
                                    ),
                                    image: avatarUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(avatarUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: avatarUrl == null
                                      ? Center(
                                          child: Text(
                                            (displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : '?'),
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            // Padding 22 from image to title
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 22,
                                bottom: 24,
                              ),
                              child: Text(
                                'Recuerdos en común',
                                style: const TextStyle(
                                  fontFamily: 'TikTokSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            sharedContent,
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
}
