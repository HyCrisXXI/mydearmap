import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/models/user_relation.dart';


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

    // Mapa para buscar tipo de relación por id del usuario relacionado
    final Map<String, String> relationLabels = {
      for (var r in relations) r.relatedUser.id: r.relationType
    };

    // Nodo central
    final centralNode = Node.Id(currentUser.id);
    graph.addNode(centralNode);

    // Crear nodos relacionados y aristas
    for (var relation in relations) {
      final related = relation.relatedUser;
      final relatedNode = Node.Id(related.id);
      graph.addNode(relatedNode);
      graph.addEdge(
        centralNode,
        relatedNode,
        paint: Paint()
          ..color = _relationColor(relation.relationType)
          ..strokeWidth = 2.5,
      );
    }

    final config = FruchtermanReingoldConfiguration();
    final algorithm = FruchtermanReingoldAlgorithm(config);

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

            // Buscar relación y usuario correspondiente
            final relatedUser = relations
                .map((r) => r.relatedUser)
                .firstWhere((u) => u.id == nodeId, orElse: () => User(id: nodeId, name: '', email: '', gender: Gender.other, createdAt: DateTime.now()));

            final label = relationLabels[nodeId] ?? '';
            return _buildUserNode(relatedUser, relationLabel: label);
          },
        ),
      ),
    );
  }

  Widget _buildUserNode(User user, {bool isCentral = false, String relationLabel = ''}) {
    final color = isCentral ? Colors.green[400] : Colors.blue[400];
    final displayName = (user.name.isNotEmpty) ? user.name : (user.email.isNotEmpty ? user.email : user.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => debugPrint('Tapped user: ${user.name}'),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
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
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 100,
          child: Column(
            children: [
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              if (relationLabel.isNotEmpty)
                Text(
                  relationLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
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
        return Colors.grey;
    }
  }
}