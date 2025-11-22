// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'core/constants/env_constants.dart';
import 'core/constants/constants.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Necesario para usar DateFormat con locales personalizadas (ej. es_ES)
  await initializeDateFormatting('es_ES');

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
    return MaterialApp(
      title: 'MyDearMap',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: AppColors.primaryColor, // Este se ve mejor
        fontFamily: 'TikTokSans',

        textTheme: ThemeData.light().textTheme.copyWith(
          titleLarge: AppTextStyles.title,
          titleMedium: AppTextStyles.subtitle,
          bodyMedium: AppTextStyles.text,
          labelLarge: AppTextStyles.textButton,
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentColor,
            textStyle: AppTextStyles.textButton,
          ),
        ),
      ),
      routes: appRoutes,
      initialRoute: '/auth',
    );
  }
}
