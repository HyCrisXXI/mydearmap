// lib/core/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onLogout;
  const AppDrawer({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Stack(
        children: [
          // Puedes agregar aquí más opciones en el futuro
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
