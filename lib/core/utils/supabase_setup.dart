// lib/core/utils/supabase_setup.dart
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSetup {
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: dotenv.get(EnvConstants.supabaseUrl),
      anonKey: dotenv.get(EnvConstants.supabaseAnonKey),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
