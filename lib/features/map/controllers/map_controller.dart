// lib/features/map/controllers/map_controller.dart
import 'package:flutter/material.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/constants/constants.dart';

enum SearchType { place, memory }

class MapScreenState {
  final LatLng? searchedLocation;
  final SearchType searchType;
  final List<MapMemory> memorySuggestions;

  MapScreenState({
    this.searchedLocation,
    this.searchType = SearchType.place,
    this.memorySuggestions = const [],
  });

  MapScreenState copyWith({
    LatLng? searchedLocation,
    SearchType? searchType,
    List<MapMemory>? memorySuggestions,
  }) {
    return MapScreenState(
      searchedLocation: searchedLocation ?? this.searchedLocation,
      searchType: searchType ?? this.searchType,
      memorySuggestions: memorySuggestions ?? this.memorySuggestions,
    );
  }
}

class MapStateController extends Notifier<MapScreenState> {
  final Map<String, Color> _memoryPinColorCache = {};
  int _colorIndex = 0;
  final List<Color> _memoryPinColors = const [
    AppColors.cian,
    AppColors.yellow,
    AppColors.orange,
    AppColors.pink,
    AppColors.purple,
  ];

  Color getStableMemoryPinColor(String memoryId) {
    if (_memoryPinColorCache.containsKey(memoryId)) {
      return _memoryPinColorCache[memoryId]!;
    }
    final color = _memoryPinColors[_colorIndex];
    _colorIndex = (_colorIndex + 1) % _memoryPinColors.length;
    _memoryPinColorCache[memoryId] = color;
    return color;
  }

  @override
  MapScreenState build() {
    return MapScreenState();
  }

  void setSearchType(SearchType newType) {
    state = state.copyWith(searchType: newType, memorySuggestions: []);
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

  void updateMemorySuggestions(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(memorySuggestions: []);
      return;
    }

    final memoriesAsync = ref.read(mapMemoriesProvider);
    if (memoriesAsync is! AsyncData<List<MapMemory>>) {
      state = state.copyWith(memorySuggestions: []);
      return;
    }

    final allMemories = memoriesAsync.value;
    final suggestions = allMemories
        .where(
          (memory) => memory.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    state = state.copyWith(memorySuggestions: suggestions);
  }
}

final mapStateControllerProvider =
    NotifierProvider<MapStateController, MapScreenState>(
      () => MapStateController(),
    );
