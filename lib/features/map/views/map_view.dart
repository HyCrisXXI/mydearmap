// lib/features/map/views/map_view.dart
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/features/map/models/map_view_model.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/memories/views/memory_form_view.dart';
import 'package:mydearmap/features/profile/views/profile_view.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/core/utils/media_url.dart';

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
        // Limpiar sugerencias de recuerdos al buscar
        viewModel.selectMemorySuggestion();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recuerdo no encontrado.')),
        );
      }
    } else {
      try {
        await viewModel.searchLocation(trimmedQuery);
        final searchedLocation = ref
            .read(mapViewModelProvider)
            .searchedLocation;
        if (searchedLocation != null) {
          mapController.move(searchedLocation, 15.0);
        }
      } catch (e) {
        if (!mounted) return;
        final message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  // Lógica para el autocompletado de recuerdos y ubicaciones
  void _onSearchQueryChanged(String query) {
    final searchType = ref.read(mapViewModelProvider).searchType;
    if (searchType == SearchType.memory) {
      ref.read(mapViewModelProvider.notifier).updateMemorySuggestions(query);
    } else {
      ref.read(mapViewModelProvider.notifier).updateLocationSuggestions(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final mapState = ref.watch(mapViewModelProvider);
    final memorySuggestions = mapState.memorySuggestions;
    final locationSuggestions = mapState.locationSuggestions;
    final currentSearchType = mapState.searchType;
    final searchedLocation = mapState.searchedLocation;

    return Scaffold(
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

            final avatarUrl = buildAvatarUrl(user?.profileUrl);

            // Avatar con letra mayúscula si no hay imagen
            final avatar = GestureDetector(
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const ProfileView()));
              },
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: AppColors.primaryColor,
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(255, 17, 17, 17),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            );

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
                                  ref
                                      .read(mapViewModelProvider.notifier)
                                      .setSearchType(result);
                                  // Actualizar sugerencias según el tipo
                                  if (result == SearchType.memory) {
                                    ref
                                        .read(mapViewModelProvider.notifier)
                                        .updateMemorySuggestions(
                                          searchController.text,
                                        );
                                  } else {
                                    ref
                                        .read(mapViewModelProvider.notifier)
                                        .updateLocationSuggestions(
                                          searchController.text,
                                        );
                                  }
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
                              final suggestionId = suggestion.id;
                              final suggestionColor = suggestionId != null
                                  ? ref
                                        .read(mapViewModelProvider.notifier)
                                        .getStableMemoryPinColor(suggestionId)
                                  : AppColors.primaryColor;
                              String? imageUrl;
                              if (suggestion.media.isNotEmpty) {
                                final images = suggestion.media
                                    .where(
                                      (m) =>
                                          m.type == MediaType.image &&
                                          m.url != null,
                                    )
                                    .toList();
                                if (images.isNotEmpty) {
                                  images.sort(
                                    (a, b) =>
                                        (a.order ?? 0).compareTo(b.order ?? 0),
                                  );
                                  imageUrl = buildMediaPublicUrl(
                                    images.first.url,
                                  );
                                }
                              }
                              final avatarSize = 32.0;
                              return ListTile(
                                leading: imageUrl != null
                                    ? Container(
                                        width: avatarSize,
                                        height: avatarSize,
                                        decoration:
                                            AppDecorations.profileAvatar(
                                              NetworkImage(imageUrl),
                                            ),
                                      )
                                    : Icon(
                                        Icons.location_on,
                                        color: suggestionColor,
                                        size: avatarSize,
                                      ),
                                title: Text(suggestion.title),
                                onTap: () {
                                  searchController.text = suggestion.title;
                                  ref
                                      .read(mapViewModelProvider.notifier)
                                      .selectMemorySuggestion();
                                  _searchAndMove(suggestion.title);
                                },
                              );
                            },
                          ),
                        ),
                      if (currentSearchType == SearchType.place &&
                          locationSuggestions.isNotEmpty)
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
                            itemCount: locationSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = locationSuggestions[index];
                              return ListTile(
                                title: Text(suggestion.name),
                                onTap: () {
                                  searchController.text = suggestion.name;
                                  mapController.move(suggestion.location, 15.0);
                                  ref
                                      .read(mapViewModelProvider.notifier)
                                      .clearLocationSuggestions();
                                  // Opcional: actualizar searchedLocation para mostrar el marcador
                                  ref
                                      .read(mapViewModelProvider.notifier)
                                      .selectLocationSuggestion(
                                        suggestion.location,
                                      );
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
                            builder: (context) => MemoryUpsertView.create(
                              initialLocation: latLng,
                            ),
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
              builder: (context) => MemoryUpsertView.create(
                initialLocation: LatLng(39.4699, -0.3763),
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: 2, // El índice del mapa
      ),
    );
  }

  // Pin del recuerdo en el mapa
  PopupMarkerLayer _buildMemoriesPopupLayer(
    List<Memory> memories,
    MapViewState mapState,
  ) {
    final viewModel = ref.read(mapViewModelProvider.notifier);
    MemoryMarker? highlightedMarker;

    // Separar recuerdos con imagen y sin imagen
    final withImage = <Memory>[];
    final withoutImage = <Memory>[];
    for (final memory in memories) {
      if (memory.location != null && memory.id != null) {
        final images = memory.media
            .where((m) => m.type == MediaType.image && m.url != null)
            .toList();
        if (images.isNotEmpty) {
          withImage.add(memory);
        } else {
          withoutImage.add(memory);
        }
      }
    }

    // Primero los marcadores SIN imagen
    final markerMarkers = withoutImage.map((memory) {
      final memoryId = memory.id!;
      final marker = MemoryMarker(
        memory: memory,
        point: LatLng(memory.location!.latitude, memory.location!.longitude),
        child: GestureDetector(
          onLongPress: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MemoryDetailView(memoryId: memoryId),
              ),
            );
          },
          child: Icon(
            Icons.location_on,
            color: viewModel.getStableMemoryPinColor(memoryId),
            size: 35,
          ),
        ),
      );
      if (memoryId == mapState.highlightedMemoryId) {
        highlightedMarker = marker;
      }
      return marker;
    });

    // Luego los marcadores CON imagen (por encima)
    final imageMarkers = withImage.map((memory) {
      final memoryId = memory.id!;
      String? imageUrl;
      final images = memory.media
          .where((m) => m.type == MediaType.image && m.url != null)
          .toList();
      if (images.isNotEmpty) {
        images.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
        imageUrl = buildMediaPublicUrl(images.first.url);
      }
      final marker = MemoryMarker(
        memory: memory,
        point: LatLng(memory.location!.latitude, memory.location!.longitude),
        child: GestureDetector(
          onLongPress: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MemoryDetailView(memoryId: memoryId),
              ),
            );
          },
          child: Container(
            width: 48.0,
            height: 48.0,
            decoration: AppDecorations.profileAvatar(NetworkImage(imageUrl!)),
          ),
        ),
      );
      if (memoryId == mapState.highlightedMemoryId) {
        highlightedMarker = marker;
      }
      return marker;
    });

    // Unir: primero los sin imagen, luego los con imagen
    final markers = [...markerMarkers, ...imageMarkers].toList();

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
  final Memory memory;

  const MemoryMarker({
    required this.memory,
    required super.point,
    required super.child,
    super.width = 40.0,
    super.height = 40.0,
  });
}
