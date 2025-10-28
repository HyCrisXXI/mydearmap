// lib/features/map/views/map_view.dart
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/widgets/app_side_menu.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/map/controllers/map_controller.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final mapController = MapController();
  final searchController = TextEditingController();
  List<MapMemory> _memorySuggestions = [];

  final List<Color> _memoryPinColors = const [
    AppColors.cian,
    AppColors.yellow,
    AppColors.orange,
    AppColors.pink,
    AppColors.purple,
  ];

  Color _getMemoryPinColor(String memoryId) {
    final int hash = memoryId.hashCode;
    final int index = hash % _memoryPinColors.length;
    return _memoryPinColors[index];
  }

  void _searchAndMove(String query) async {
    if (query.trim().isEmpty) {
      _memorySuggestions = [];
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final mapState = ref.read(mapStateControllerProvider);
    final searchType = mapState.searchType;

    _memorySuggestions = [];

    if (searchType == SearchType.memory) {
      final memoriesAsync = ref.read(mapMemoriesProvider);
      List<MapMemory> memories = [];
      if (memoriesAsync is AsyncData<List<MapMemory>>) {
        memories = memoriesAsync.value;
      }

      MapMemory? matchingMemory;
      try {
        matchingMemory = memories.firstWhere(
          (mem) => mem.title.toLowerCase() == query.toLowerCase(),
          orElse: () => memories.firstWhere(
            (mem) => mem.title.toLowerCase().contains(query.toLowerCase()),
          ),
        );
      } catch (e) {
        matchingMemory = null;
      }

      if (matchingMemory != null && matchingMemory.location != null) {
        final location = LatLng(
          matchingMemory.location!.latitude,
          matchingMemory.location!.longitude,
        );
        mapController.move(location, 15.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recuerdo encontrado: ${matchingMemory.title}'),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recuerdo no encontrado.')),
        );
      }
    } else {
      final searchNotifier = ref.read(mapStateControllerProvider.notifier);
      try {
        await searchNotifier.searchLocation(query);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  // Lógica para el autocompletado de recuerdos
  void _onSearchQueryChanged(String query) {
    final searchType = ref.read(mapStateControllerProvider).searchType;
    if (searchType == SearchType.memory && query.isNotEmpty) {
      setState(() {
        _memorySuggestions = ref
            .read(mapStateControllerProvider.notifier)
            .getMemorySuggestions(query);
      });
    } else {
      setState(() {
        _memorySuggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final mapMemoriesAsync = ref.watch(mapMemoriesProvider);

    final mapState = ref.watch(mapStateControllerProvider);
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
                                  ref
                                      .read(mapStateControllerProvider.notifier)
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
                          _memorySuggestions.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                color: Colors.grey.withAlpha(
                                  (255 * 0.2).round(),
                                ),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _memorySuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _memorySuggestions[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on,
                                  color: _getMemoryPinColor(suggestion.id),
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
                    options: const MapOptions(
                      initialCenter: LatLng(39.4699, -0.3763), // Valencia
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://api.maptiler.com/maps/dataviz/{z}/{x}/{y}.png?key=${EnvConstants.mapTilesApiKey}',
                        userAgentPackageName: 'com.mydearmap.app',
                        tileProvider: kIsWeb ? NetworkTileProvider() : null,
                      ),
                      mapMemoriesAsync.when(
                        data: (memories) => _buildMemoriesMarkerLayer(memories),
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
          // TODO: Navigate to add memory screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  MarkerLayer _buildMemoriesMarkerLayer(List<MapMemory> memories) {
    final markers = memories.where((memory) => memory.location != null).map((
      memory,
    ) {
      return Marker(
        point: LatLng(memory.location!.latitude, memory.location!.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Recuerdo: ${memory.title}')),
            );
          },
          child: Icon(
            Icons.location_on,
            color: _getMemoryPinColor(memory.id),
            size: 35,
          ),
        ),
      );
    }).toList();

    return MarkerLayer(markers: markers);
  }
}
