// lib/core/constants/env_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConstants {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL', fallback: '');

  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  static String get mapTilesApiKey {
    final keys = [
      dotenv.get('MAP_TILES_API_KEY_1', fallback: ''),
      dotenv.get('MAP_TILES_API_KEY_2', fallback: ''),
      dotenv.get('MAP_TILES_API_KEY_3', fallback: ''),
      dotenv.get('MAP_TILES_API_KEY_4', fallback: ''),
      dotenv.get('MAP_TILES_API_KEY_5', fallback: ''),
    ].where((k) => k.isNotEmpty).toList();

    if (keys.isEmpty) return dotenv.get('MAP_TILES_API_KEY', fallback: '');

    return keys[DateTime.now().millisecond % keys.length];
  }

  static String get geminiApiKey => dotenv.get('GEMINI_API_KEY', fallback: '');
}
