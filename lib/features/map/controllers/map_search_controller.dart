// lib/features/map/controllers/map_search_controller.dart
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapSearchController extends Notifier<LatLng?> {
  @override
  LatLng? build() {
    return null;
  }

  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    final url = Uri.parse(
      'https://api.maptiler.com/geocoding/${Uri.encodeComponent(query)}.json?key=${EnvConstants.mapTilesApiKey}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coords = data['features'][0]['geometry']['coordinates'];
          final lng = coords[0] as double;
          final lat = coords[1] as double;
          state = LatLng(lat, lng);
        } else {
          state = null;
          throw Exception('No se encontró el lugar.');
        }
      } else {
        state = null;
        throw Exception('Error en la API de geocodificación.');
      }
    } catch (e) {
      state = null;
      rethrow;
    }
  }
}

final mapSearchControllerProvider =
    NotifierProvider<MapSearchController, LatLng?>(() => MapSearchController());
