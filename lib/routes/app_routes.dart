import 'package:flutter/material.dart';
import 'package:mydearmap/core/widgets/auth_gate.dart';
import 'package:mydearmap/features/map/views/map_view.dart';
import 'package:mydearmap/features/profile/views/profile_view.dart';
import 'package:mydearmap/features/memories/views/memories_view.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';

// Importar aquí las demás vistas cuando existan

final Map<String, WidgetBuilder> appRoutes = {
  '/auth': (context) => AuthGate(),
  '/chatbot': (context) => Scaffold(
    appBar: AppBar(title: const Text('Chatbot')),
    body: const Center(child: Text('Chatbot View Placeholder')),
    bottomNavigationBar: AppNavBar(
      currentIndex: 0, // El índice del chatbot
    ),
  ),
  '/memories': (context) => MemoriesView(),
  '/map': (context) => MapView(),
  '/notifications': (context) => Scaffold(
    appBar: AppBar(title: const Text('Notificaciones')),
    body: const Center(child: Text('Notifications View Placeholder')),
    bottomNavigationBar: AppNavBar(
      currentIndex: 3, // El índice de las notificaciones
    ),
  ),
  '/profile': (context) => ProfileView(),
};
