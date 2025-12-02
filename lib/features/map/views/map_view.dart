// lib/features/map/views/map_view.dart
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/features/map/models/map_view_model.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/memories/views/memory_form_view.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/features/memories/models/memory_filters.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final mapController = MapController();
  final searchController = TextEditingController();
  final PopupController _popupController = PopupController();

  MemoryFilterCriteria _activeFilters = MemoryFilterCriteria.empty;

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

  Future<void> _openFiltersSheet() async {
    final memories = ref.read(mapViewModelProvider).memories.asData?.value;
    if (memories == null || memories.isEmpty) {
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
    final userOptions = MemoryFilterUtils.buildUserOptions(
      memories: memories,
      currentUser: currentUser,
      relations: relations,
    );
    if (!mounted) return;
    final updated = await showMemoryFiltersSheet(
      context: context,
      initialCriteria: _activeFilters,
      userOptions: userOptions,
      suggestedZoneCenter: _tryGetMapCenter(),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _activeFilters = updated;
    });
  }

  LatLng? _tryGetMapCenter() {
    try {
      return mapController.camera.center;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapViewModelProvider);
    final memorySuggestions = mapState.memorySuggestions;
    final locationSuggestions = mapState.locationSuggestions;
    final currentSearchType = mapState.searchType;
    final searchedLocation = mapState.searchedLocation;

    // --- lógica para los pins de recuerdos ---
    List<Marker> memoryMarkers = [];
    mapState.memories.when(
      data: (memories) {
        final filteredMemories = MemoryFilterUtils.applyFilters(
          memories,
          _activeFilters,
        );
        final withImage = <Memory>[];
        final withoutImage = <Memory>[];
        for (final memory in filteredMemories) {
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
        memoryMarkers.addAll(
          withoutImage.map((memory) {
            return MemoryMarker(
              memory: memory,
              point: LatLng(
                memory.location!.latitude,
                memory.location!.longitude,
              ),
              width: 46.0,
              height: 46.0,
              child: GestureDetector(
                onLongPress: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          MemoryDetailView(memoryId: memory.id!),
                    ),
                  );
                },
                child: Container(
                  width: 46.0,
                  height: 46.0,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppIcons.pin,
                      width: 32.0,
                      height: 32.0,
                      colorFilter: const ColorFilter.mode(
                        AppColors.accentColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
        memoryMarkers.addAll(
          withImage.map((memory) {
            String? imageUrl;
            final images = memory.media
                .where((m) => m.type == MediaType.image && m.url != null)
                .toList();
            if (images.isNotEmpty) {
              images.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
              imageUrl = buildMediaPublicUrl(images.first.url);
            }
            return MemoryMarker(
              memory: memory,
              point: LatLng(
                memory.location!.latitude,
                memory.location!.longitude,
              ),
              width: 56.0,
              height: 56.0,
              child: GestureDetector(
                onLongPress: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          MemoryDetailView(memoryId: memory.id!),
                    ),
                  );
                },
                child: Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: AppDecorations.profileAvatar(
                    NetworkImage(imageUrl!),
                  ),
                ),
              ),
            );
          }),
        );
      },
      loading: () {},
      error: (err, stack) {},
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filtros y toggle
            Padding(
              padding: const EdgeInsets.only(
                top: 30.0,
                left: 44.0,
                right: 36.0,
              ),
              child: Row(
                children: [
                  // Toggle de lugares
                  Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: GestureDetector(
                      onTap: () {
                        final newType = currentSearchType == SearchType.place
                            ? SearchType.memory
                            : SearchType.place;
                        ref
                            .read(mapViewModelProvider.notifier)
                            .setSearchType(newType);
                        // Actualizar sugerencias según el tipo
                        if (newType == SearchType.memory) {
                          ref
                              .read(mapViewModelProvider.notifier)
                              .updateMemorySuggestions(searchController.text);
                        } else {
                          ref
                              .read(mapViewModelProvider.notifier)
                              .updateLocationSuggestions(searchController.text);
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            'Lugares',
                            style: TextStyle(
                              color: currentSearchType == SearchType.place
                                  ? AppColors.accentColor
                                  : AppColors.textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SvgPicture.asset(
                            currentSearchType == SearchType.place
                                ? AppIcons.toggleButtonOn
                                : AppIcons.toggleButtonOff,
                            width: 32,
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    style: AppButtonStyles.circularIconButton,
                    icon: SvgPicture.asset(
                      AppIcons.listFilter,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        _activeFilters.hasFilters
                            ? AppColors.accentColor
                            : AppColors.textColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: _openFiltersSheet,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: AppButtonStyles.circularIconButton,
                    icon: SvgPicture.asset(
                      AppIcons.plus,
                      width: 22,
                      height: 22,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MemoryUpsertView.create(
                            initialLocation: LatLng(39.4699, -0.3763),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Separación vertical entre filtros y búsqueda
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 42.0,
              ), // Más margen a los lados
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: _onSearchQueryChanged,
                    decoration: InputDecoration(
                      hintText: currentSearchType == SearchType.place
                          ? 'Buscar lugares'
                          : 'Buscar recuerdos',
                      hintStyle: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 16,
                      ),
                      border: const UnderlineInputBorder(),
                      prefixIcon: null,
                      suffixIcon: IconButton(
                        icon: SvgPicture.asset(
                          AppIcons.search,
                          width: 22,
                          height: 22,
                        ),
                        onPressed: () => _searchAndMove(searchController.text),
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
                          bottomLeft: Radius.circular(AppSizes.borderRadius),
                          bottomRight: Radius.circular(AppSizes.borderRadius),
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
                          final suggestionColor = AppColors.primaryColor;
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
                              imageUrl = buildMediaPublicUrl(images.first.url);
                            }
                          }
                          final avatarSize = 32.0;
                          return ListTile(
                            leading: imageUrl != null
                                ? Container(
                                    width: avatarSize,
                                    height: avatarSize,
                                    decoration: AppDecorations.profileAvatar(
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
                          bottomLeft: Radius.circular(AppSizes.borderRadius),
                          bottomRight: Radius.circular(AppSizes.borderRadius),
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
            const SizedBox(height: 18),
            Expanded(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(39.4699, -0.3763), // Valencia
                  initialZoom: 13,
                  onLongPress: (tapPosition, latLng) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            MemoryUpsertView.create(initialLocation: latLng),
                      ),
                    );
                  },
                  minZoom: 3,
                  maxZoom: 19,
                  cameraConstraint: CameraConstraint.contain(
                    bounds: LatLngBounds(LatLng(-90, -180), LatLng(90, 180)),
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
                  PopupMarkerLayer(
                    options: PopupMarkerLayerOptions(
                      popupController: _popupController,
                      markers: memoryMarkers,
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
                  ),
                  if (_activeFilters.zone != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(
                            _activeFilters.zone!.center.latitude,
                            _activeFilters.zone!.center.longitude,
                          ),
                          useRadiusInMeter: true,
                          radius: _activeFilters.zone!.radiusMeters,
                          color: AppColors.accentColor.withValues(alpha: .12),
                          borderStrokeWidth: 2,
                          borderColor: AppColors.accentColor.withValues(
                            alpha: .6,
                          ),
                        ),
                      ],
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
        ),
      ),
      floatingActionButton: null, // Eliminar el FAB de añadir
      bottomNavigationBar: AppNavBar(
        currentIndex: 2, // El índice del mapa
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
