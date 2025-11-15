// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'core/constants/env_constants.dart';
import 'core/constants/constants.dart';
import 'core/widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: EnvConstants.supabaseUrl,
    anonKey: EnvConstants.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentColor,
      surface: AppColors.backgroundColor,
    );

    return MaterialApp(
      title: 'MyDearMap',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: baseScheme,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        fontFamily: 'TikTokSans',
        textTheme: ThemeData.light().textTheme.copyWith(
          titleLarge: AppTextStyles.title,
          titleMedium: AppTextStyles.subtitle,
          bodyMedium: AppTextStyles.text,
          labelLarge: AppTextStyles.textButton,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
