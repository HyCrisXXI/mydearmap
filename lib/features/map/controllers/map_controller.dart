// lib/features/map/controllers/map_controller.dart
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';

enum SearchType { place, memory }

class MapScreenState {
  final LatLng? searchedLocation;
  final SearchType searchType;

  MapScreenState({this.searchedLocation, this.searchType = SearchType.place});

  MapScreenState copyWith({LatLng? searchedLocation, SearchType? searchType}) {
    return MapScreenState(
      searchedLocation: searchedLocation ?? this.searchedLocation,
      searchType: searchType ?? this.searchType,
    );
  }
}

class MapStateController extends Notifier<MapScreenState> {
  @override
  MapScreenState build() {
    return MapScreenState();
  }

  void setSearchType(SearchType newType) {
    state = state.copyWith(searchType: newType);
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
          state = state.copyWith(searchedLocation: LatLng(lat, lng));
        } else {
          state = state.copyWith(searchedLocation: null);
          throw Exception('No se encontró el lugar.');
        }
      } else {
        state = state.copyWith(searchedLocation: null);
        throw Exception('Error en la API de geocodificación.');
      }
    } catch (e) {
      state = state.copyWith(searchedLocation: null);
      rethrow;
    }
  }

  List<MapMemory> getMemorySuggestions(String query) {
    if (query.trim().isEmpty) {
      return [];
    }

    final memoriesAsync = ref.read(mapMemoriesProvider);

    if (memoriesAsync is! AsyncData<List<MapMemory>>) {
      return [];
    }

    final allMemories = memoriesAsync.value;

    return allMemories
        .where(
          (memory) => memory.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}

final mapStateControllerProvider =
    NotifierProvider<MapStateController, MapScreenState>(
      () => MapStateController(),
    );
