// lib/features/map/views/map_view.dart
import 'package:mydearmap/features/auth/controllers/auth_controller.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:mydearmap/features/relations/views/relation_view.dart';


class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  final mapController = MapController();
  final searchController = TextEditingController();
  LatLng? searchedLocation;

  Future<void> searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    final url = Uri.parse(
      'https://api.maptiler.com/geocoding/${Uri.encodeComponent(query)}.json?key=${EnvConstants.mapTilesApiKey}',
    );
    final response = await http.get(url);
    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final coords = data['features'][0]['geometry']['coordinates'];
        final lng = coords[0] as double;
        final lat = coords[1] as double;
        setState(() {
          searchedLocation = LatLng(lat, lng);
        });
        mapController.move(LatLng(lat, lng), mapController.camera.zoom);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el lugar.')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error buscando el lugar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        onLogout: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cerrar sesión'),
              content: const Text(
                '¿Estás seguro de que quieres cerrar sesión?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sí, cerrar sesión'),
                ),
              ],
            ),
          );
          if (shouldLogout == true) {
            try {
              await ref.read(authControllerProvider.notifier).signOut();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cerrar sesión: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        onOpenRelations: () {
          Navigator.of(context).pop(); // cierra drawer
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RelationCreateView(),
            ),
          );
        },
      ),
      
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final userAsync = ref.watch(currentUserProvider);
            return userAsync.when(
              data: (userObj) {
                final user = userObj;
                String greeting() {
                  final hour = DateTime.now().hour;
                  if (hour >= 6 && hour < 12) return '¡Buenos días';
                  if (hour >= 12 && hour < 20) return '¡Buenas tardes';
                  return 'Buenas noches';
                }

                final name = user?.name ?? 'Usuario';
                const avatarRadius = 25.0; // Tamaño del avatar
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
                          // Botón de Menú
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                            ),
                          ),

                          // Texto de Saludo
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
                    // Buscador
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar recuerdos o lugares...',
                          prefixIcon: const Icon(Icons.search),
                          // Reducimos el padding vertical para achicar la altura
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 10.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () => searchPlace(searchController.text),
                          ),
                        ),
                        onSubmitted: searchPlace,
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
                                  point: searchedLocation!,
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
          // 
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
