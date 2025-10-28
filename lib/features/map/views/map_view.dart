// lib/features/map/views/map_view.dart
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/widgets/app_side_menu.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/map/models/map_view_model.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mydearmap/features/memories/views/memory_detail_edit_view.dart';
import 'dart:convert';
import 'package:mydearmap/features/relations/views/relation_view.dart';
import 'package:mydearmap/features/memories/views/memory_create_view.dart';


class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final mapController = MapController();
  final searchController = TextEditingController();
  final _popupController = PopupController();

  @override
  void dispose() {
    mapController.dispose();
    searchController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  void _searchAndMove(String query) async {
    final trimmedQuery = query.trim();
    final viewModel = ref.read(mapViewModelProvider.notifier);

    if (trimmedQuery.isEmpty) {
      viewModel.clearMemorySuggestions();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final searchType = ref.read(mapViewModelProvider).searchType;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (searchType == SearchType.memory) {
      final matchingMemory = viewModel.findMemoryByQuery(trimmedQuery);

      if (matchingMemory != null && matchingMemory.location != null) {
        final location = LatLng(
          matchingMemory.location!.latitude,
          matchingMemory.location!.longitude,
        );
        mapController.move(location, 15.0);
        viewModel.highlightMemory(matchingMemory.id);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recuerdo no encontrado.')),
        );
      }
    } else {
      try {
        await viewModel.searchLocation(trimmedQuery);
      } catch (e) {
        if (!mounted) return;
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  // Lógica para el autocompletado de recuerdos
  void _onSearchQueryChanged(String query) {
    if (ref.read(mapViewModelProvider).searchType == SearchType.memory) {
      ref.read(mapViewModelProvider.notifier).updateMemorySuggestions(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final mapState = ref.watch(mapViewModelProvider);
    final memorySuggestions = mapState.memorySuggestions;
    final currentSearchType = mapState.searchType;
    final searchedLocation = mapState.searchedLocation;

    return Scaffold(
      drawer: const AppSideMenu(),
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            String greeting() {
              final hour = DateTime.now().hour;
              if (hour >= 6 && hour < 12) return 'Buenos días';
              if (hour >= 12 && hour < 20) return 'Buenas tardes';
              return 'Buenas noches';
            }

            final name = user?.name ?? 'Usuario';
            const avatarRadius = 25.0;
            Widget avatar;
            if (user != null &&
                user.profileUrl != null &&
                user.profileUrl!.isNotEmpty) {
              avatar = CircleAvatar(
                radius: avatarRadius,
                backgroundImage: NetworkImage(
                  "https://oomglkpxogeiwrrfphon.supabase.co/storage/v1/object/public/media/avatars/${user.profileUrl!}",
                ),
              );
            } else {
              avatar = const CircleAvatar(
                radius: avatarRadius,
                child: Icon(Icons.person, size: avatarRadius),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4.0,
                    right: 16.0,
                    top: 8.0,
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${greeting()}, $name',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      avatar,
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        onChanged: _onSearchQueryChanged,
                        decoration: InputDecoration(
                          hintText: currentSearchType == SearchType.memory
                              ? 'Buscar recuerdos...'
                              : 'Buscar lugares...',
                          prefixIcon: Icon(
                            currentSearchType == SearchType.memory
                                ? Icons.bookmark
                                : Icons.search,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadius,
                            ),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () =>
                                    _searchAndMove(searchController.text),
                              ),
                              PopupMenuButton<SearchType>(
                                initialValue: currentSearchType,
                                onSelected: (SearchType result) {
                                  searchController.clear();
                                  ref
                                      .read(mapViewModelProvider.notifier)
                                      .setSearchType(result);
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<SearchType>>[
                                      const PopupMenuItem<SearchType>(
                                        value: SearchType.place,
                                        child: Text('Buscar lugares'),
                                      ),
                                      const PopupMenuItem<SearchType>(
                                        value: SearchType.memory,
                                        child: Text('Buscar recuerdos'),
                                      ),
                                    ],
                                icon: Icon(
                                  currentSearchType == SearchType.memory
                                      ? Icons.bookmark_border
                                      : Icons.location_on_outlined,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        onSubmitted: _searchAndMove,
                      ),
                      if (currentSearchType == SearchType.memory &&
                          memorySuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(
                                AppSizes.borderRadius,
                              ),
                              bottomRight: Radius.circular(
                                AppSizes.borderRadius,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: .2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: memorySuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = memorySuggestions[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on,
                                  color: ref
                                      .read(mapViewModelProvider.notifier)
                                      .getStableMemoryPinColor(suggestion.id),
                                ),
                                title: Text(suggestion.title),
                                onTap: () {
                                  searchController.text = suggestion.title;
                                  _searchAndMove(suggestion.title);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: LatLng(39.4699, -0.3763), // Valencia
                      initialZoom: 13,
                      onLongPress: (TapPosition tapPosition, LatLng latLng) {                            
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>  MemoryCreateView(initialLocation: latLng),
                            ),
                            );
                          },
                      minZoom: 3,
                      maxZoom: 19,
                      cameraConstraint: CameraConstraint.contain(
                        bounds: LatLngBounds(
                          LatLng(-90, -180),
                          LatLng(90, 180),
                        ),
                      ),
                      interactionOptions: InteractionOptions(
                        flags:
                            InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.drag |
                            InteractiveFlag.flingAnimation |
                            InteractiveFlag.scrollWheelZoom,
                      ),
                      onTap: (_, _) {
                        _popupController.hideAllPopups();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://api.maptiler.com/maps/dataviz/{z}/{x}/{y}.png?key=${EnvConstants.mapTilesApiKey}',
                        userAgentPackageName: 'com.mydearmap.app',
                        tileProvider: kIsWeb ? NetworkTileProvider() : null,
                        maxNativeZoom: 19,
                      ),
                      mapState.memories.when(
                        data: (memories) =>
                            _buildMemoriesPopupLayer(memories, mapState),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.transparent,
                          ),
                        ),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),
                      if (searchedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: searchedLocation,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
              Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>  MemoryCreateView(initialLocation: LatLng(39.4699, -0.3763)),
                            ),
                          );
          // TODO: Navigate to add memory screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Pin del recuerdo en el mapa
  PopupMarkerLayer _buildMemoriesPopupLayer(
    List<MapMemory> memories,
    MapViewState mapState,
  ) {
    final viewModel = ref.read(mapViewModelProvider.notifier);
    MemoryMarker? highlightedMarker;

    final markers = memories.where((memory) => memory.location != null).map((
      memory,
    ) {
      final marker = MemoryMarker(
        memory: memory,
        point: LatLng(memory.location!.latitude, memory.location!.longitude),
        child: GestureDetector(
          onLongPress: () {
            // TODO: Placeholder para navegar a la pantalla de detalle del recuerdo.
            // Se pasa el ID del recuerdo para que la siguiente pantalla
            // pueda cargar los detalles completos desde la base de datos.
            /*
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MemoryDetailView(memoryId: memory.id),
            ),
          );
          */
          },
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recuerdo: ${memory.title}')),
            );
          },
          onDoubleTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MemoryDetailEditView(memoryId: memory.id),
              ),
            );
          },
          child: Icon(
            Icons.location_on,
            color: viewModel.getStableMemoryPinColor(memory.id),
            size: 35,
          ),
        ),
      );

      if (memory.id == mapState.highlightedMemoryId) {
        highlightedMarker = marker;
      }

      return marker;
    }).toList();

    if (highlightedMarker != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _popupController.showPopupsOnlyFor([highlightedMarker!]);
        viewModel.highlightMemory(null);
      });
    }

    return PopupMarkerLayer(
      options: PopupMarkerLayerOptions(
        popupController: _popupController,
        markers: markers,
        popupDisplayOptions: PopupDisplayOptions(
          builder: (BuildContext context, Marker marker) {
            if (marker is MemoryMarker) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // Nombre del recuerdo
                child: Text(
                  marker.memory.title,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          snap: PopupSnap.markerTop,
        ),
      ),
    );
  }
}

class MemoryMarker extends Marker {
  final MapMemory memory;

  const MemoryMarker({
    required this.memory,
    required super.point,
    required super.child,
    super.width = 40.0,
    super.height = 40.0,
  });
}
