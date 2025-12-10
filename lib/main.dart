// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'core/constants/env_constants.dart';
import 'core/constants/constants.dart';
import 'routes/app_routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

// Esta es la lógica que permite un main background para toda la app (salvo en las pantallas
// que se diga lo contrario)
class AppBackground extends StatefulWidget {
  final Widget child;
  final String? backgroundImage;
  const AppBackground({required this.child, this.backgroundImage, super.key});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground> {
  final ScrollController _bgScrollController = ScrollController();

  @override
  void dispose() {
    _bgScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: SingleChildScrollView(
                controller: _bgScrollController,
                physics: const NeverScrollableScrollPhysics(),
                child: Image.asset(
                  widget.backgroundImage ?? AppIcons.mainBG,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollStartNotification ||
                  notification is ScrollEndNotification) {
                if (notification.metrics.axis == Axis.vertical) {
                  if (_bgScrollController.hasClients) {
                    _bgScrollController.jumpTo(notification.metrics.pixels);
                  }
                }
              }
              return false;
            },
            child: widget.child,
          ),
        ],
      ),
    );
  }
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
        scaffoldBackgroundColor: AppColors.primaryColor,
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
        inputDecorationTheme: AppInputStyles.defaultInputDecorationTheme,
      ),
      routes: appRoutes,
      initialRoute: '/auth',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return AppBackground(child: child ?? const SizedBox());
      },
    );
  }
}
