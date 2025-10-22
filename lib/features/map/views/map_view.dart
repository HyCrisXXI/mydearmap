import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/env_constants.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el lugar.')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error buscando el lugar.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Mapa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
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
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: const Icon(Icons.person, size: 32),
                ),
                const SizedBox(width: 16),
                const Text('Usuario', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar recuerdos o lugares...',
                prefixIcon: const Icon(Icons.search),
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
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/dataviz/{z}/{x}/{y}.png?key=${EnvConstants.mapTilesApiKey}',
                  userAgentPackageName: 'com.mydearmap.app',
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
