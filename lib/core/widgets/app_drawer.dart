// lib/core/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback? onOpenRelations;
  const AppDrawer({super.key, required this.onLogout, this.onOpenRelations});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          // Puedes agregar aquí más opciones en el futuro
          const SizedBox.expand(), 
          Align(
            alignment: Alignment.topLeft,
            child: ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Relaciones'),
              onTap: onOpenRelations,
            ),
          ),
          const SizedBox.expand(),
          Align(
            alignment: Alignment.bottomLeft,
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}
