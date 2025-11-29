// lib/features/memories/views/memories_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/features/timecapsules/views/timecapsules_view.dart';
import 'package:mydearmap/core/widgets/memories_grid.dart';
import 'package:mydearmap/features/relations/views/relations_view.dart';
import 'package:mydearmap/features/memories/views/memory_form_view.dart';
import 'package:mydearmap/features/timeline/view/timeline_view.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MemoriesView extends ConsumerStatefulWidget {
  const MemoriesView({super.key});

  @override
  ConsumerState<MemoriesView> createState() => _MemoriesViewState();
}

class _MemoriesViewState extends ConsumerState<MemoriesView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(userMemoriesProvider));
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(userMemoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis recuerdos'),
        actions: [
          // Botón Timeline a la izquierda de los demás
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
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
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: SvgPicture.asset(AppIcons.timer),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TimeCapsulesView()),
                );
              },
              style: AppButtonStyles.circularIconButton,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: SvgPicture.asset(AppIcons.heartHandshake),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RelationsView()),
                );
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
                  MaterialPageRoute(
                    builder: (_) => MemoryUpsertView.create(
                      initialLocation: LatLng(39.4699, -0.3763),
                    ),
                  ),
                );
              },
              style: AppButtonStyles.circularIconButton,
            ),
          ),
        ],
      ),
      // Quita el Padding externo
      body: memoriesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) =>
            Center(child: Text('No se pudieron cargar los recuerdos: $error')),
        data: (memories) {
          if (memories.isEmpty) {
            return const Center(
              child: Text('Todavía no has guardado ningún recuerdo.'),
            );
          }

          return MemoriesGrid(
            memories: memories,
            showFeatured: true,
            onMemoryTap: (memory) {
              final memoryId = memory.id ?? '';
              if (memoryId.isEmpty) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MemoryDetailView(memoryId: memoryId),
                ),
              );
            },
            // Añade padding inferior para el nav bar
            gridPadding: const EdgeInsets.fromLTRB(
              AppSizes.paddingLarge,
              AppSizes.paddingLarge,
              AppSizes.paddingLarge,
              80, // o el alto de tu nav bar + extra
            ),
          );
        },
      ),
      bottomNavigationBar: AppNavBar(currentIndex: 1),
    );
  }
}
