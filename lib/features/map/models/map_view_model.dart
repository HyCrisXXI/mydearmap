// lib/features/map/models/map_view_model.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/user.dart';

enum SearchType { place, memory }

class MapViewState {
  final AsyncValue<List<Memory>> memories;
  final SearchType searchType;
  final List<Memory> memorySuggestions;
  final String memoryQuery;
  final LatLng? searchedLocation;
  final String? highlightedMemoryId;
  final List<LocationSuggestion> locationSuggestions;

  const MapViewState({
    this.memories = const AsyncValue.loading(),
    this.searchType = SearchType.place,
    this.memorySuggestions = const [],
    this.memoryQuery = '',
    this.searchedLocation,
    this.highlightedMemoryId,
    this.locationSuggestions = const [],
  });

  MapViewState copyWith({
    AsyncValue<List<Memory>>? memories,
    SearchType? searchType,
    List<Memory>? memorySuggestions,
    String? memoryQuery,
    LatLng? searchedLocation,
    String? highlightedMemoryId,
    List<LocationSuggestion>? locationSuggestions,
    bool resetHighlight = false,
  }) {
    return MapViewState(
      memories: memories ?? this.memories,
      searchType: searchType ?? this.searchType,
      memorySuggestions: memorySuggestions ?? this.memorySuggestions,
      memoryQuery: memoryQuery ?? this.memoryQuery,
      searchedLocation: searchedLocation ?? this.searchedLocation,
      highlightedMemoryId: resetHighlight
          ? null
          : (highlightedMemoryId ?? this.highlightedMemoryId),
      locationSuggestions: locationSuggestions ?? this.locationSuggestions,
    );
  }
}

// Nueva clase para sugerencias de ubicación
class LocationSuggestion {
  final String name;
  final LatLng location;

  LocationSuggestion({required this.name, required this.location});
}

class MapViewModel extends Notifier<MapViewState> {
  final Map<String, Color> _memoryPinColorCache = {};
  int _colorIndex = 0;
  final List<Color> _memoryPinColors = const [
    AppColors.blue,
    AppColors.yellow,
    AppColors.orange,
    AppColors.pink,
    AppColors.green,
  ];

  @override
  MapViewState build() {
    final initialMemories = ref.read(userMemoriesProvider);

    ref.onDispose(() {
      _memoryPinColorCache.clear();
      _colorIndex = 0;
    });

    ref.listen<AsyncValue<User?>>(currentUserProvider, (previous, next) {
      final prevId = _userIdFromAsync(previous);
      final nextId = _userIdFromAsync(next);
      if (prevId != nextId) {
        Future.microtask(() {
          _memoryPinColorCache.clear();
          _colorIndex = 0;
          state = const MapViewState();
          ref.invalidate(userMemoriesProvider);
        });
      }
    });

    ref.listen<AsyncValue<List<Memory>>>(userMemoriesProvider, (
      previous,
      next,
    ) {
      Future.microtask(() {
        final nextMemories = next.asData?.value ?? const <Memory>[];
        state = state.copyWith(
          memories: next,
          memorySuggestions: _recomputeSuggestions(
            query: state.memoryQuery,
            memories: nextMemories,
          ),
        );
      });
    });

    return MapViewState(memories: initialMemories);
  }

  String? _userIdFromAsync(AsyncValue<User?>? asyncUser) {
    return asyncUser?.whenOrNull(data: (user) => user?.id);
  }

  Color getStableMemoryPinColor(String memoryId) {
    if (_memoryPinColorCache.containsKey(memoryId)) {
      return _memoryPinColorCache[memoryId]!;
    }
    final color = _memoryPinColors[_colorIndex];
    _colorIndex = (_colorIndex + 1) % _memoryPinColors.length;
    _memoryPinColorCache[memoryId] = color;
    return color;
  }

  void setSearchType(SearchType newType) {
    state = state.copyWith(searchType: newType, resetHighlight: true);
  }

  void clearMemorySuggestions() {
    state = state.copyWith(
      memorySuggestions: const [],
      memoryQuery: '',
      resetHighlight: true,
    );
  }

  void clearLocationSuggestions() {
    state = state.copyWith(locationSuggestions: const []);
  }

  void updateMemorySuggestions(String query) {
    if (query.trim().isEmpty) {
      clearMemorySuggestions();
      return;
    }

    final memories = state.memories.asData?.value ?? const <Memory>[];
    final filtered = _recomputeSuggestions(query: query, memories: memories);
    state = state.copyWith(memorySuggestions: filtered, memoryQuery: query);
  }

  List<Memory> _recomputeSuggestions({
    required String query,
    required List<Memory> memories,
  }) {
    if (query.trim().isEmpty) {
      return const [];
    }

    return memories
        .where(
          (memory) => memory.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  Memory? findMemoryByQuery(String query) {
    if (query.trim().isEmpty) return null;
    final memories = state.memories.asData?.value;
    if (memories == null || memories.isEmpty) {
      return null;
    }

    try {
      return memories.firstWhere(
        (memory) => memory.title.toLowerCase() == query.toLowerCase(),
        orElse: () {
          return memories.firstWhere(
            (memory) =>
                memory.title.toLowerCase().contains(query.toLowerCase()),
          );
        },
      );
    } catch (_) {
      return null;
    }
  }

  void highlightMemory(String? memoryId) {
    state = state.copyWith(
      highlightedMemoryId: memoryId,
      resetHighlight: memoryId == null,
    );
  }

  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    final url = Uri.parse(
      'https://api.maptiler.com/geocoding/${Uri.encodeComponent(query)}.json?key=${EnvConstants.mapTilesApiKey}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? const [];
        if (features.isEmpty) {
          state = state.copyWith(searchedLocation: null);
          throw Exception('No se encontró el lugar.');
        }
        final firstFeature = features.first as Map<String, dynamic>;
        final coords = firstFeature['geometry']['coordinates'] as List<dynamic>;
        final lng = (coords[0] as num).toDouble();
        final lat = (coords[1] as num).toDouble();
        state = state.copyWith(searchedLocation: LatLng(lat, lng));
      } else {
        state = state.copyWith(searchedLocation: null);
        throw Exception('Error en la API de geocodificación.');
      }
    } catch (e) {
      state = state.copyWith(searchedLocation: null);
      rethrow;
    }
  }

  Future<void> updateLocationSuggestions(String query) async {
    if (query.trim().isEmpty) {
      clearLocationSuggestions();
      return;
    }
    final url = Uri.parse(
      'https://api.maptiler.com/geocoding/${Uri.encodeComponent(query)}.json?autocomplete=true&key=${EnvConstants.mapTilesApiKey}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? const [];
        final suggestions = features.map((feature) {
          final f = feature as Map<String, dynamic>;
          final coords = f['geometry']['coordinates'] as List<dynamic>;
          final lng = (coords[0] as num).toDouble();
          final lat = (coords[1] as num).toDouble();
          final name = f['place_name'] ?? f['text'] ?? '';
          return LocationSuggestion(name: name, location: LatLng(lat, lng));
        }).toList();
        state = state.copyWith(locationSuggestions: suggestions);
      } else {
        state = state.copyWith(locationSuggestions: []);
      }
    } catch (_) {
      state = state.copyWith(locationSuggestions: []);
    }
  }

  void selectLocationSuggestion(LatLng location) {
    state = state.copyWith(searchedLocation: location, locationSuggestions: []);
  }

  void selectMemorySuggestion() {
    state = state.copyWith(memorySuggestions: []);
  }
}

final mapViewModelProvider =
    NotifierProvider.autoDispose<MapViewModel, MapViewState>(MapViewModel.new);
