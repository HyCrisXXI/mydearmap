import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/env_constants.dart';

final reverseGeocodeProvider = FutureProvider.family
    .autoDispose<String, LatLng>((ref, point) async {
      final uri = Uri.https(
        'api.maptiler.com',
        '/geocoding/${point.longitude},${point.latitude}.json',
        {
          'key': EnvConstants.mapTilesApiKey,
          'language': 'es',
          'types': 'street',
          'limit': '1',
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
          'No se pudo obtener la dirección (${response.statusCode})',
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final features = payload['features'];
      if (features is! List || features.isEmpty) {
        throw Exception('Sin resultados de geocodificación');
      }

      final feature = features.first;
      if (feature is! Map<String, dynamic>) {
        throw Exception('Respuesta inválida');
      }

      final properties = feature['properties'];
      if (properties is Map<String, dynamic>) {
        final street = properties['name'] ?? properties['street'];
        if (street is String && street.trim().isNotEmpty) {
          return street.trim();
        }
      }

      final placeName = feature['place_name'] ?? feature['text'];
      if (placeName is String && placeName.trim().isNotEmpty) {
        final withoutZip = placeName
            .replaceAll(RegExp(r'\b\d{5}\b'), '')
            .trim();
        return withoutZip.isNotEmpty ? withoutZip : placeName.trim();
      }

      throw Exception('No se pudo interpretar la dirección');
    });
