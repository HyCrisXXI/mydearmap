// lib/features/map/views/map_view.dart
import 'dart:math';

import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/features/map/models/map_view_model.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mydearmap/features/map/widgets/memory_info_card.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/memories/views/create_join_memory.dart';
import 'package:mydearmap/core/widgets/app_search_bar.dart';
import 'package:mydearmap/features/memories/views/memory_form_view.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/features/memories/models/memory_filters.dart';
import 'package:mydearmap/core/widgets/pulse_button.dart';

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final mapController = MapController();
  final searchController = TextEditingController();
  Memory? _selectedMemory;

  MemoryFilterCriteria _activeFilters = MemoryFilterCriteria.empty;
  final ValueNotifier<double> _zoomNotifier = ValueNotifier(13.0);

  // Cache para evitar recálculos en cada frame de zoom
  List<Memory>? _cachedMemories;
  List<Memory>? _cachedFilteredWithImage;
  List<Memory>? _cachedFilteredWithoutImage;
  MemoryFilterCriteria? _cachedFilters;
  // Mapa para cachear URLs de imágenes y orden
  final Map<String, String> _memoryImageUrlCache = {};

  List<Marker> _cachedStaticMarkers = [];

  @override
  void dispose() {
    mapController.dispose();
    searchController.dispose();

    _zoomNotifier.dispose();
    super.dispose();
  }

  void _searchAndMove(String query) async {
    final trimmedQuery = query.trim();
    final viewModel = ref.read(mapViewModelProvider.notifier);

    if (trimmedQuery.isEmpty) {
      viewModel.clearMemorySuggestions();
      viewModel.clearLocationSuggestions();
      viewModel.clearSearchedLocation();
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

  void _updateCache(List<Memory> currentMemoriesData) {
    _cachedMemories = currentMemoriesData;
    _cachedFilters = _activeFilters;
    _memoryImageUrlCache.clear();
    _cachedFilteredWithImage = [];
    _cachedFilteredWithoutImage = [];
    _cachedStaticMarkers = [];

    final filteredMemories = MemoryFilterUtils.applyFilters(
      currentMemoriesData,
      _activeFilters,
    );

    for (final memory in filteredMemories) {
      if (memory.location != null && memory.id != null) {
        final images = memory.media
            .where((m) => m.type == MediaType.image && m.url != null)
            .toList();

        if (images.isNotEmpty) {
          _cachedFilteredWithImage!.add(memory);
          // Pre-calc url
          images.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
          final url = buildMediaPublicUrl(images.first.url);
          if (url != null) {
            _memoryImageUrlCache[memory.id!] = url;
          }
        } else {
          _cachedFilteredWithoutImage!.add(memory);
        }
      }
    }

    // Pre-construir marcadores estáticos (zoom <= 14, size = 56.0 o 46.0)
    final staticMarkers = <Marker>[];
    if (_cachedFilteredWithoutImage != null) {
      staticMarkers.addAll(
        _cachedFilteredWithoutImage!.map((m) => _buildNoImageMarker(m, 46.0)),
      );
    }
    if (_cachedFilteredWithImage != null) {
      staticMarkers.addAll(
        _cachedFilteredWithImage!.map((m) => _buildImageMarker(m, 56.0)),
      );
    }
    _cachedStaticMarkers = staticMarkers;
  }

  Marker _buildNoImageMarker(Memory memory, double size) {
    return MemoryMarker(
      memory: memory,
      point: LatLng(memory.location!.latitude, memory.location!.longitude),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMemory = memory;
          });
        },
        onLongPress: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MemoryDetailView(memoryId: memory.id!),
            ),
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              AppIcons.pin,
              width: size * 0.7,
              height: size * 0.7, // Proporcional
              colorFilter: const ColorFilter.mode(
                AppColors.accentColor,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Marker _buildImageMarker(Memory memory, double size) {
    final imageUrl = _memoryImageUrlCache[memory.id];
    if (imageUrl == null) {
      return const Marker(point: LatLng(0, 0), child: SizedBox());
    }
    return MemoryMarker(
      memory: memory,
      point: LatLng(memory.location!.latitude, memory.location!.longitude),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMemory = memory;
          });
        },
        onLongPress: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MemoryDetailView(memoryId: memory.id!),
            ),
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: AppDecorations.profileAvatar(NetworkImage(imageUrl)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapViewModelProvider);
    final memorySuggestions = mapState.memorySuggestions;
    final locationSuggestions = mapState.locationSuggestions;
    final currentSearchType = mapState.searchType;
    final searchedLocation = mapState.searchedLocation;

    // --- lógica para los pins de recuerdos ---

    // Obtenemos la data actual pero no ejecutamos lógica pesada si no ha cambiado
    final currentMemoriesData = mapState.memories.asData?.value;

    if (currentMemoriesData != null) {
      // Verificamos si necesitamos recalcular los filtros
      final shouldrecalculate =
          _cachedMemories != currentMemoriesData ||
          _cachedFilters != _activeFilters;

      if (shouldrecalculate) {
        _updateCache(currentMemoriesData);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filtros y toggle
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.upperPadding,
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
                  PulseButton(
                    child: IconButton(
                      style: AppButtonStyles.circularIconButton,
                      icon: SvgPicture.asset(
                        AppIcons.funnel,
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
                  ),
                  const SizedBox(width: 8),
                  PulseButton(
                    child: IconButton(
                      style: AppButtonStyles.circularIconButton,
                      icon: SvgPicture.asset(
                        AppIcons.plus,
                        width: 22,
                        height: 22,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateJoinMemoryView(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Separación vertical entre filtros y búsqueda
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
              ), // Más margen a los lados
              child: Column(
                children: [
                  AppSearchBar(
                    controller: searchController,
                    onChanged: _onSearchQueryChanged,
                    hintText: currentSearchType == SearchType.place
                        ? 'Buscar lugares'
                        : 'Buscar recuerdos',
                    onSuffixPressed: () =>
                        _searchAndMove(searchController.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: LatLng(39.4699, -0.3763), // Valencia
                      initialZoom: 13,
                      onLongPress: (tapPosition, latLng) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MemoryUpsertView.create(
                              initialLocation: latLng,
                            ),
                          ),
                        );
                      },
                      minZoom: 2,
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
                      onPositionChanged: (camera, hasGesture) {
                        _zoomNotifier.value = camera.zoom;
                        if (hasGesture && _selectedMemory != null) {
                          setState(() {
                            _selectedMemory = null;
                          });
                        }
                      },
                      onTap: (_, _) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        ref
                            .read(mapViewModelProvider.notifier)
                            .clearMemorySuggestions();
                        ref
                            .read(mapViewModelProvider.notifier)
                            .clearLocationSuggestions();

                        if (_selectedMemory != null) {
                          setState(() {
                            _selectedMemory = null;
                          });
                        }
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
                      _activeFilters.zone != null
                          ? CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: LatLng(
                                    _activeFilters.zone!.center.latitude,
                                    _activeFilters.zone!.center.longitude,
                                  ),
                                  useRadiusInMeter: true,
                                  radius: _activeFilters.zone!.radiusMeters,
                                  color: AppColors.accentColor.withValues(
                                    alpha: .12,
                                  ),
                                  borderStrokeWidth: 2,
                                  borderColor: AppColors.accentColor.withValues(
                                    alpha: .6,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      if (searchedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: searchedLocation,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    AppIcons.pin,
                                    width: 28.0,
                                    height: 28.0,
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.accentColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ValueListenableBuilder<double>(
                        valueListenable: _zoomNotifier,
                        builder: (context, currentZoom, child) {
                          if (currentZoom <= 14 &&
                              _cachedStaticMarkers.isNotEmpty) {
                            return MarkerLayer(markers: _cachedStaticMarkers);
                          }

                          final markers = <Marker>[];

                          // 1. Añadir marcadores sin imagen (tamaño fijo)
                          if (_cachedFilteredWithoutImage != null) {
                            markers.addAll(
                              _cachedFilteredWithoutImage!.map((memory) {
                                return _buildNoImageMarker(memory, 46.0);
                              }),
                            );
                          }

                          // 2. Añadir marcadores con imagen (tamaño dinámico)
                          if (_cachedFilteredWithImage != null) {
                            final size = 56.0 + pow(currentZoom - 14, 2) * 10;
                            // Clamp seguro
                            final clampedSize = size < 20.0 ? 20.0 : size;

                            markers.addAll(
                              _cachedFilteredWithImage!.map((memory) {
                                return _buildImageMarker(memory, clampedSize);
                              }),
                            );
                          }

                          return MarkerLayer(markers: markers);
                        },
                      ),
                    ],
                  ),

                  // Suggestions Layer (Floating)
                  if ((currentSearchType == SearchType.memory &&
                          memorySuggestions.isNotEmpty) ||
                      (currentSearchType == SearchType.place &&
                          locationSuggestions.isNotEmpty))
                    Positioned(
                      top: 0,
                      left: 42,
                      right: 42,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 170),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(AppSizes.borderRadius),
                            bottomRight: Radius.circular(AppSizes.borderRadius),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(AppSizes.borderRadius),
                            bottomRight: Radius.circular(AppSizes.borderRadius),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: currentSearchType == SearchType.memory
                                ? memorySuggestions.length
                                : locationSuggestions.length,
                            itemBuilder: (context, index) {
                              if (currentSearchType == SearchType.memory) {
                                final suggestion = memorySuggestions[index];
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
                                      (a, b) => (a.order ?? 0).compareTo(
                                        b.order ?? 0,
                                      ),
                                    );
                                    imageUrl = buildMediaPublicUrl(
                                      images.first.url,
                                    );
                                  }
                                }
                                const avatarSize = 32.0;
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
                                      : Container(
                                          width: avatarSize,
                                          height: avatarSize,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: SvgPicture.asset(
                                              AppIcons.pin,
                                              width: 20.0,
                                              height: 20.0,
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    AppColors.accentColor,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          ),
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
                              } else {
                                final suggestion = locationSuggestions[index];
                                return ListTile(
                                  title: Text(suggestion.name),
                                  onTap: () {
                                    searchController.text = suggestion.name;
                                    mapController.move(
                                      suggestion.location,
                                      15.0,
                                    );
                                    ref
                                        .read(mapViewModelProvider.notifier)
                                        .clearLocationSuggestions();
                                    ref
                                        .read(mapViewModelProvider.notifier)
                                        .selectLocationSuggestion(
                                          suggestion.location,
                                        );
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                  if (_selectedMemory != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: MemoryInfoCard(
                          memory: _selectedMemory!,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MemoryDetailView(
                                  memoryId: _selectedMemory!.id!,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
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
