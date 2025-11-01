// ...existing code...
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/features/relations/controllers/relation_controller.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/features/relations/views/relation_view.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart' show currentUserProvider;
import 'package:mydearmap/data/repositories/user_relation_repository.dart';

class AllRelationView extends ConsumerWidget {
  const AllRelationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error cargando usuario: $e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('No hay usuario autenticado')));
        }

        final relationsAsync = ref.watch(userRelationsProvider(user.id));

        return relationsAsync.when(
          loading: () => Scaffold(appBar: AppBar(title: Text('Relaciones de ${user.name}')), body: const Center(child: CircularProgressIndicator())),
          error: (e, st) => Scaffold(appBar: AppBar(title: Text('Relaciones de ${user.name}')), body: Center(child: Text('Error cargando relaciones: $e'))),
          data: (relations) => UserRelationGraph(currentUser: user, relations: relations),
        );
      },
    );
  }
}

/// Graph radial layout + painter implementation
class UserRelationGraph extends ConsumerWidget {
  final User currentUser;
  final List<UserRelation> relations;

  const UserRelationGraph({
    super.key,
    required this.currentUser,
    required this.relations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // canvas size (ajústalo si quieres más/menos espacio)
    final mq = MediaQuery.of(context).size;
    final canvasWidth = mq.width * 1.6;
    final canvasHeight = (mq.height - kToolbarHeight) * 1.4;
    final center = Offset(canvasWidth / 2, canvasHeight / 2);

    // node visual params
    const double centralSize = 120;
    const double nodeSize = 88;

    // radius: aumenta con número de nodos, pero limita para que no salga demasiado
    final int n = relations.length;
    final double baseRadius = min(canvasWidth, canvasHeight) / 3;
    final double radius = (n <= 6) ? baseRadius : baseRadius + (n - 6) * 18;

    // calcular posiciones radiales
    final List<_NodePos> nodePositions = [];
    for (var i = 0; i < n; i++) {
      final angle = -pi / 2 + (2 * pi * i) / (n == 0 ? 1 : n); // empezar arriba
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);
      final related = relations[i].relatedUser;
      nodePositions.add(_NodePos(
        user: related,
        relationType: relations[i].relationType,
        position: Offset(dx, dy),
      ));
    }

    // central node position
    final centralPos = Offset(center.dx - centralSize / 2, center.dy - centralSize / 2);

    return Scaffold(
      appBar: AppBar(title: Text('Red de ${currentUser.name}')),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(200),
        minScale: 0.2,
        maxScale: 4.0,
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: Stack(
            children: [
              // Painter: aristas y etiquetas
              CustomPaint(
                size: Size(canvasWidth, canvasHeight),
                painter: _EdgesPainter(
                  center: Offset(center.dx, center.dy),
                  centralSize: centralSize,
                  nodes: nodePositions,
                  nodeSize: nodeSize,
                ),
              ),

              // Central node
              Positioned(
                left: centralPos.dx,
                top: centralPos.dy,
                child: _buildUserNode(
                  context,
                  ref,
                  currentUser,
                  size: centralSize,
                  isCentral: true,
                ),
              ),

              // Related nodes
              for (final np in nodePositions)
                Positioned(
                  left: np.position.dx - nodeSize / 2,
                  top: np.position.dy - nodeSize / 2,
                  child: _buildUserNode(
                    context,
                    ref,
                    np.user,
                    size: nodeSize,
                    relationLabel: np.relationType,
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Añadir relación',
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RelationCreateView()));
        },
      ),
    );
  }

  Widget _buildUserNode(BuildContext context, WidgetRef ref, User user, {required double size, bool isCentral = false, String relationLabel = ''}) {
    final color = isCentral ? Colors.green[400] : Colors.blue[400];
    final displayName = (user.name.isNotEmpty) ? user.name : (user.email.isNotEmpty ? user.email : user.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => debugPrint('Tapped user: ${user.name}'),
          onLongPress: isCentral ? null : () => _onNodeLongPress(context, ref, user, relationLabel),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
            ),
            child: ClipOval(
              child: user.profileUrl != null && user.profileUrl!.isNotEmpty
                  ? Image.network(
                      user.profileUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(displayName.isNotEmpty ? displayName[0] : '?')),
                    )
                  : Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0] : '?',
                        style: TextStyle(color: Colors.white, fontSize: size / 3, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
        ),
        if (relationLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: max(80, size),
            child: Text(
              relationLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (relationLabel.isEmpty) const SizedBox(height: 4),
      ],
    );
  }

  Future<void> _onNodeLongPress(BuildContext context, WidgetRef ref, User related, String currentRelationLabel) async {
    final choice = await showModalBottomSheet<String?>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar relación'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Eliminar relación', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancelar'),
              onTap: () => Navigator.of(context).pop(null),
            ),
          ],
        ),
      ),
    );

    if (choice == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eliminar relación'),
          content: Text('¿Eliminar relación con ${related.name.isNotEmpty ? related.name : related.email}?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
          ],
        ),
      );
      if (confirm != true) return;

      try {
        // Usar relatedUserIdentifier extraído del nodo
        await ref.read(relationControllerProvider.notifier).deleteRelation(
              currentUserId: currentUser.id,
              relatedUserId: related.id,
              relationType: currentRelationLabel,
            );
        ref.invalidate(userRelationsProvider(currentUser.id));
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relación eliminada')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando relación: $e')));
      }
    } else if (choice == 'edit') {
      final TextEditingController controller = TextEditingController(text: currentRelationLabel);
      final newLabel = await showDialog<String?>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Editar relación'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Tipo de relación'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Guardar')),
          ],
        ),
      );

      if (newLabel == null || newLabel.isEmpty) return;

      try {
        // actualizar usando relatedUserIdentifier extraído del nodo
        await ref.read(relationControllerProvider.notifier).deleteRelation(
              currentUserId: currentUser.id,
              relatedUserId: related.id,
              relationType: currentRelationLabel,
            );
        await ref.read(relationControllerProvider.notifier).createRelation(
              currentUserId: currentUser.id,
              relatedUserIdentifier: related.id,
              relationType: newLabel,
            );
        ref.invalidate(userRelationsProvider(currentUser.id));
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Relación actualizada')));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error editando relación: $e')));
      }
    }
  }
}

class _NodePos {
  final User user;
  final String relationType;
  final Offset position;
  _NodePos({required this.user, required this.relationType, required this.position});
}

class _EdgesPainter extends CustomPainter {
  final Offset center;
  final double centralSize;
  final List<_NodePos> nodes;
  final double nodeSize;

  _EdgesPainter({
    required this.center,
    required this.centralSize,
    required this.nodes,
    required this.nodeSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    final Offset centralCenter = Offset(center.dx, center.dy);

    for (final np in nodes) {
      // puntos: desde borde del central hasta borde del nodo relacionado
      final target = np.position;
      final from = centralCenter;
      final to = target;

      // calcular dirección y desplazar para que la línea termine en el borde de los círculos
      final dir = (to - from);
      final dist = dir.distance;
      if (dist <= 0.001) continue;
      final unit = dir / dist;

      final fromOffset = from + unit * (centralSize / 2);
      final toOffset = to - unit * (nodeSize / 2);

      // color según tipo
      linePaint.color = _relationColor(np.relationType);
      canvas.drawLine(fromOffset, toOffset, linePaint);

      // dibujar etiqueta en el punto medio, ligeramente desplazada perpendicularmente
      final mid = Offset((fromOffset.dx + toOffset.dx) / 2, (fromOffset.dy + toOffset.dy) / 2);

      final perp = Offset(-unit.dy, unit.dx) * 12; // desplazamiento perpendicular
      final labelPos = mid + perp;

      textPainter.text = TextSpan(
        text: np.relationType,
        style: const TextStyle(color: Colors.black87, fontSize: 12, backgroundColor: Colors.white70),
      );
      textPainter.layout();
      final lp = labelPos - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, lp);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter old) {
    return old.nodes != nodes || old.center != center;
  }

  Color _relationColor(String type) {
    switch (type.toLowerCase()) {
      case 'amigo':
        return Colors.blueAccent;
      case 'familiar':
        return Colors.redAccent;
      case 'pareja':
        return Colors.pinkAccent;
      case 'compañero':
        return Colors.orangeAccent;
      default:
        return Colors.grey.shade600;
    }
  }
}
// ...existing code...