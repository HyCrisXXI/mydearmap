// lib/features/map/views/map_view.dart
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/widgets/app_side_menu.dart';
import 'package:mydearmap/features/map/controllers/map_search_controller.dart';
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

  void _searchAndMove(String query) async {
    final searchNotifier = ref.read(mapSearchControllerProvider.notifier);
    try {
      await searchNotifier.searchLocation(query);
      final newLocation = ref.read(mapSearchControllerProvider);
      if (newLocation != null) {
        mapController.move(newLocation, mapController.camera.zoom);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchedLocation = ref.watch(mapSearchControllerProvider);

    return Scaffold(
      drawer: const AppSideMenu(),
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final userAsync = ref.watch(currentUserProvider);
            return userAsync.when(
              data: (userObj) {
                final user = userObj;
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
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
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar recuerdos o lugares...',
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 10.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () =>
                                _searchAndMove(searchController.text),
                          ),
                        ),
                        onSubmitted: _searchAndMove,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Expanded(
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: LatLng(39.4699, -0.3763), // Valencia
                          initialZoom: 13,
                          minZoom: 2.0,
                          maxZoom: 18.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://api.maptiler.com/maps/dataviz/{z}/{x}/{y}.png?key=${EnvConstants.mapTilesApiKey}',
                            userAgentPackageName: 'com.mydearmap.app',
                            tileProvider: kIsWeb ? NetworkTileProvider() : null,
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
            );
          },
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
}
