import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/features/auth/controllers/auth_controller.dart';
import 'package:mydearmap/features/relations/views/relation_nodes_view.dart'
    show RelationOverviewView;
import 'package:mydearmap/features/memories/views/all_memories_view.dart';
import 'package:mydearmap/features/timeline/view/timeline_view.dart';
import 'package:mydearmap/features/relations/views/relations_view.dart';

// Deprecated: Se usará AppNavBar a partir de ahora
class AppSideMenu extends ConsumerWidget {
  const AppSideMenu({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        if (context.mounted) Navigator.of(context).pop(); // cerrar drawer
        await ref.read(authControllerProvider.notifier).signOut();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleNavigation(BuildContext context, Widget targetView) {
    if (context.mounted) {
      Navigator.of(context).pop(); // cerrar drawer
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => targetView));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'MyDearMap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Menú Principal',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text('Línea de Tiempo'),
            onTap: () =>
                _handleNavigation(context, const MemoriesTimelineView()),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Mis Recuerdos'),
            onTap: () => _handleNavigation(context, const MemoriesView()),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Ver Relaciones Nodo'),
            onTap: () =>
                _handleNavigation(context, const RelationOverviewView()),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Ver Relaciones'),
            onTap: () => _handleNavigation(context, const RelationsView()),
          ),
          const Spacer(),
          // Cerrar sesión
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () => _handleLogout(context, ref),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
