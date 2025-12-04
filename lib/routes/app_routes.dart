import 'package:flutter/material.dart';
import 'package:mydearmap/core/widgets/auth_gate.dart';
import 'package:mydearmap/core/widgets/app_shell.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/auth': (context) => AuthGate(),
  '/chatbot': (context) => const AppShell(initialIndex: 0),
  '/memories': (context) => const AppShell(initialIndex: 1),
  '/map': (context) => const AppShell(initialIndex: 2),
  '/notifications': (context) => const AppShell(initialIndex: 3),
  '/profile': (context) => const AppShell(initialIndex: 4),
};
