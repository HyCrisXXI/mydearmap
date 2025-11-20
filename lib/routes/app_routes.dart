import 'package:flutter/material.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import 'package:mydearmap/core/widgets/auth_gate.dart';
import 'package:mydearmap/features/ai_chat/views/ai_chat_view.dart';
import 'package:mydearmap/features/map/views/map_view.dart';
import 'package:mydearmap/features/memories/views/memories_view.dart';
import 'package:mydearmap/features/notifications/views/notifications_view.dart';
import 'package:mydearmap/features/profile/views/profile_view.dart';

// Importar aquí las demás vistas cuando existan

final Map<String, WidgetBuilder> appRoutes = {
  '/auth': (context) => AuthGate(),
  '/chatbot': (context) => AiChatView(),
  '/memories': (context) => MemoriesView(),
  '/map': (context) => MapView(),
  '/notifications': (context) => const NotificationsView(),
  '/profile': (context) => ProfileView(),
};
