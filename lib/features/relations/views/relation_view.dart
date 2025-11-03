import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:graphview/GraphView.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart'
    show currentUserProvider;
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/features/relations/controllers/relation_controller.dart'
    show relationControllerProvider;

class RelationCreateView extends ConsumerStatefulWidget {
  const RelationCreateView({super.key});

  @override
  RelationCreateViewState createState() => RelationCreateViewState();
}

class RelationCreateViewState extends ConsumerState<RelationCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _relationController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _userController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Obtener usuario actual
    final currentUserId = _currentUserIdFromRef(ref);

    if (currentUserId == null || currentUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actual no disponible')),
        );
      }
      return;
    }

    final relatedIdentifier = _userController.text.trim();
    final relationType = _relationController.text.trim();
    setState(() => _loading = true);

    try {
      await ref
          .read(relationControllerProvider.notifier)
          .createRelation(
            currentUserId: currentUserId,
            relatedUserIdentifier: relatedIdentifier,
            relationType: relationType,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relación añadida correctamente')),
      );
      Navigator.of(context).pop(true); // devuelve éxito
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir la relación: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _currentUserIdFromRef(WidgetRef ref) {
    final dynamic val = ref.read(currentUserProvider);
    // Si es AsyncValue<User?>
    if (val is AsyncValue<User?>) {
      final user = val.asData?.value;
      return user?.id;
    }
    // Si el provider devuelve directamente User
    if (val is User) return val.id;
    // Fallback dinámico seguro
    try {
      final dyn = val as dynamic;
      final id = dyn?.id;
      return id?.toString();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir relación')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Usuario a añadir (id/email/nombre según tu implementación)
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: 'Usuario (id o email)',
                  hintText: 'Introduce el id o email del usuario',
                  prefixIcon: Icon(Icons.person_add),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Introduce un usuario'
                    : null,
              ),
              const SizedBox(height: 12),
              // Nombre/tipo de la relación
              TextFormField(
                controller: _relationController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de relación',
                  hintText: 'ej. amigo, familiar, compañero',
                  prefixIcon: Icon(Icons.label),
                ),
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Introduce el tipo de relación'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_loading ? 'Guardando...' : 'Guardar relación'),
                  onPressed: _loading ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
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


    final algorithm = FruchtermanReingoldAlgorithm();

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
*/
