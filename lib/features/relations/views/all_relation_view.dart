import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart' show currentUserProvider;
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/features/relations/controllers/relation_controller.dart' show relationControllerProvider;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;


class UserRelationGraph extends StatelessWidget {
  final User currentUser;
  final List<UserRelation> relations;

  const UserRelationGraph({
    super.key,
    required this.currentUser,
    required this.relations,
  });

  @override
  Widget build(BuildContext context) {
    final graph = Graph()..isTree = false;

    // Crear nodo del usuario central
    final centralNode = Node.Id(currentUser.id);
    graph.addNode(centralNode);

    // Crear nodos de los relacionados y conectarlos
    for (var relation in relations) {
      final related = relation.relatedUser;

      final relatedNode = Node.Id(related.id);
      graph.addEdge(
        centralNode,
        relatedNode,
        paint: Paint()
          ..color = _relationColor(relation.relationType)
          ..strokeWidth = 2.5,
      );
    }


    final builder = FruchtermanReingoldConfiguration();

    final algorithm = FruchtermanReingoldAlgorithm(builder);


    return Scaffold(
      appBar: AppBar(title: const Text('Red de relaciones')),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.01,
        maxScale: 5.0,
        child: GraphView(
          graph: graph,
          algorithm: algorithm,
          paint: Paint()
            ..color = Colors.grey
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
          builder: (Node node) {
            final nodeId = node.key!.value as String;
            if (nodeId == currentUser.id) {
              return _buildUserNode(currentUser, isCentral: true);
            }

            final relatedUser = relations
                .map((r) => r.relatedUser)
                .firstWhere((u) => u.id == nodeId);

            return _buildUserNode(relatedUser);
          },
        ),
      ),
    );
  }

  /// Círculo con imagen o iniciales del usuario
  Widget _buildUserNode(User user, {bool isCentral = false}) {
    final color = isCentral ? Colors.green[400] : Colors.blue[400];

    return GestureDetector(
      onTap: () {
        // Puedes abrir el perfil o mostrar detalles
        debugPrint('Tapped user: ${user.name}');
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: const [
            BoxShadow(blurRadius: 4, color: Colors.black26)
          ],
        ),
        child: ClipOval(
          child: user.profileUrl != null
              ? Image.network(
                  user.profileUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Center(child: Text(user.name[0])),
                )
              : Center(
                  child: Text(
                    user.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// Color según tipo de relación
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
        return Colors.grey;
    }
  }
}
