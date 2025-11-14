// lib/features/relations/views/relation_node_view.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart'
    show currentUserProvider;
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/models/user_relation.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart'
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

class RelationOverviewView extends ConsumerWidget {
  const RelationOverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Error cargando usuario: $error'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('No hay usuario autenticado')),
          );
        }

        final relationsAsync = ref.watch(userRelationsProvider(user.id));

        return relationsAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(title: Text('Relaciones de ${user.name}')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: Text('Relaciones de ${user.name}')),
            body: Center(child: Text('Error cargando relaciones: $error')),
          ),
          data: (relations) =>
              UserRelationGraph(currentUser: user, relations: relations),
        );
      },
    );
  }
}

class UserRelationGraph extends ConsumerWidget {
  const UserRelationGraph({
    super.key,
    required this.currentUser,
    required this.relations,
  });

  final User currentUser;
  final List<UserRelation> relations;

  static const double _centralNodeSize = 120;
  static const double _relatedNodeSize = 88;
  static const double _ringPadding = 12;
  static const double _nodeGap = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedRelations = [...relations]
      ..sort((a, b) => a.relationType.compareTo(b.relationType));

    return Scaffold(
      appBar: AppBar(title: Text('Red de ${currentUser.name}')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final size = Size(width, height);
          final center = Offset(width / 2, height / 2);

          final nodePositions = _computeNodePositions(
            sortedRelations,
            center,
            size,
          );

          // Agrupar nodos por tipo de relación
          final relationGroups = <String, List<_NodePos>>{};
          for (final node in nodePositions) {
            relationGroups.putIfAbsent(node.relationType, () => []).add(node);
          }

          return InteractiveViewer(
            minScale: 0.75,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(48),
            child: SizedBox.expand(
              child: Stack(
                children: [
                  CustomPaint(
                    size: size,
                    painter: _EdgesPainter(
                      center: center,
                      centralSize: _centralNodeSize,
                      nodes: nodePositions,
                      nodeSize: _relatedNodeSize,
                      relationGroups: relationGroups,
                    ),
                  ),
                  Positioned(
                    left: center.dx - _centralNodeSize / 2,
                    top: center.dy - _centralNodeSize / 2,
                    child: _buildUserNode(
                      context,
                      ref,
                      currentUser,
                      size: _centralNodeSize,
                      isCentral: true,
                    ),
                  ),
                  for (final node in nodePositions)
                    Positioned(
                      left: node.position.dx - _relatedNodeSize / 2,
                      top: node.position.dy - _relatedNodeSize / 2,
                      child: _buildUserNode(
                        context,
                        ref,
                        node.user,
                        size: _relatedNodeSize,
                        relationLabel: node.relationType,
                      ),
                    ),
                  if (nodePositions.isEmpty)
                    Center(
                      child: Text(
                        'Todavía no tienes relaciones registradas.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Añadir relación',
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RelationCreateView()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<_NodePos> _computeNodePositions(
    List<UserRelation> relations,
    Offset center,
    Size canvasSize,
  ) {
    if (relations.isEmpty) return const [];

    final n = relations.length;
    final minDimension = math.min(canvasSize.width, canvasSize.height);
    final availableRadius = math.max(
      0.0,
      (minDimension / 2) - (_relatedNodeSize / 2) - _ringPadding,
    );

    final minRadiusForCenterClearance =
        (_centralNodeSize / 2) + (_relatedNodeSize / 2) + _nodeGap;
    final circumferencePerNode = _relatedNodeSize + _nodeGap;
    final minRadiusForSpacing = (circumferencePerNode * n) / (2 * math.pi);

    final desiredRadius = math.max(
      minRadiusForCenterClearance,
      minRadiusForSpacing,
    );

    var radius = desiredRadius.clamp(0, availableRadius).toDouble();

    final expansion = n <= 4
        ? 180.0
        : n <= 8
        ? 120.0
        : 80.0;
    radius = math.min(availableRadius, radius + expansion);

    return List.generate(n, (index) {
      final fraction = index / n;
      final angle = -math.pi / 2 + (2 * math.pi * fraction);
      final offset = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final relation = relations[index];
      return _NodePos(
        user: relation.relatedUser,
        relationType: relation.relationType,
        position: offset,
      );
    });
  }

  Widget _buildUserNode(
    BuildContext context,
    WidgetRef ref,
    User user, {
    required double size,
    bool isCentral = false,
    String relationLabel = '',
  }) {
    final color = isCentral ? Colors.green[400] : Colors.blue[400];
    final displayName = user.name.isNotEmpty
        ? user.name
        : (user.email.isNotEmpty ? user.email : user.id);
    final avatarUrl = buildAvatarUrl(user.profileUrl);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => debugPrint('Tapped user: ${user.name}'),
          onLongPress: isCentral
              ? null
              : () => _onNodeLongPress(context, ref, user, relationLabel),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: const [
                BoxShadow(blurRadius: 6, color: Colors.black26),
              ],
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          displayName.isNotEmpty ? displayName[0] : '?',
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0] : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size / 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: math.max(80, size),
          child: Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Future<void> _onNodeLongPress(
    BuildContext context,
    WidgetRef ref,
    User related,
    String currentRelationLabel,
  ) async {
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
              title: const Text(
                'Eliminar relación',
                style: TextStyle(color: Colors.red),
              ),
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
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eliminar relación'),
          content: Text(
            '¿Eliminar relación con ${related.name.isNotEmpty ? related.name : related.email}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (!context.mounted || confirm != true) return;

      try {
        await ref
            .read(relationControllerProvider.notifier)
            .deleteRelation(
              currentUserId: currentUser.id,
              relatedUserId: related.id,
              relationType: currentRelationLabel,
            );
        ref.invalidate(userRelationsProvider(currentUser.id));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Relación eliminada')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error eliminando relación: $e')),
          );
        }
      }
    } else if (choice == 'edit') {
      final controller = TextEditingController(text: currentRelationLabel);
      if (!context.mounted) return;
      final newLabel = await showDialog<String?>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Editar relación'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Tipo de relación'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      if (!context.mounted || newLabel == null || newLabel.isEmpty) return;

      try {
        await ref
            .read(relationControllerProvider.notifier)
            .deleteRelation(
              currentUserId: currentUser.id,
              relatedUserId: related.id,
              relationType: currentRelationLabel,
            );
        await ref
            .read(relationControllerProvider.notifier)
            .createRelation(
              currentUserId: currentUser.id,
              relatedUserIdentifier: related.id,
              relationType: newLabel,
            );
        ref.invalidate(userRelationsProvider(currentUser.id));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Relación actualizada')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error editando relación: $e')),
          );
        }
      }
    }
  }
}

class _NodePos {
  const _NodePos({
    required this.user,
    required this.relationType,
    required this.position,
  });

  final User user;
  final String relationType;
  final Offset position;
}

class _EdgesPainter extends CustomPainter {
  const _EdgesPainter({
    required this.center,
    required this.centralSize,
    required this.nodes,
    required this.nodeSize,
    required this.relationGroups,
  });

  final Offset center;
  final double centralSize;
  final List<_NodePos> nodes;
  final double nodeSize;
  final Map<String, List<_NodePos>> relationGroups;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final Offset centralCenter = center;

    // Dibujar por grupos de tipo de relación
    for (final entry in relationGroups.entries) {
      final relationType = entry.key;
      final groupNodes = entry.value;

      if (groupNodes.isEmpty) continue;

      // Calcular punto intermedio promedio para el grupo
      final avgX =
          groupNodes.map((n) => n.position.dx).reduce((a, b) => a + b) /
          groupNodes.length;
      final avgY =
          groupNodes.map((n) => n.position.dy).reduce((a, b) => a + b) /
          groupNodes.length;
      final groupCenter = Offset(avgX, avgY);

      // Calcular punto de ramificación (entre el centro y el punto promedio del grupo)
      final branchPoint = Offset(
        centralCenter.dx + (groupCenter.dx - centralCenter.dx) * 0.4,
        centralCenter.dy + (groupCenter.dy - centralCenter.dy) * 0.4,
      );

      // Dibujar línea principal desde el centro hasta el punto de ramificación
      final dirToBranch = branchPoint - centralCenter;
      final distToBranch = dirToBranch.distance;
      if (distToBranch > 0.001) {
        final unitToBranch = dirToBranch / distToBranch;
        final fromCenter = centralCenter + unitToBranch * (centralSize / 2);

        linePaint.color = _relationColor(relationType);
        canvas.drawLine(fromCenter, branchPoint, linePaint);

        // Dibujar etiqueta del tipo de relación en la línea principal
        final mid = Offset(
          (fromCenter.dx + branchPoint.dx) / 2,
          (fromCenter.dy + branchPoint.dy) / 2,
        );
        final perp = Offset(-unitToBranch.dy, unitToBranch.dx) * 12;
        final labelPos = mid + perp;

        textPainter.text = TextSpan(
          text: relationType,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            backgroundColor: Colors.white70,
          ),
        );
        textPainter.layout();
        final offset =
            labelPos - Offset(textPainter.width / 2, textPainter.height / 2);
        textPainter.paint(canvas, offset);
      }

      // Dibujar líneas desde el punto de ramificación a cada nodo del grupo
      for (final node in groupNodes) {
        final dirToNode = node.position - branchPoint;
        final distToNode = dirToNode.distance;
        if (distToNode <= 0.001) continue;

        final unitToNode = dirToNode / distToNode;
        final toNode = node.position - unitToNode * (nodeSize / 2);

        linePaint.color = _relationColor(relationType).withValues(alpha: 0.7);
        canvas.drawLine(branchPoint, toNode, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EdgesPainter oldDelegate) {
    return oldDelegate.nodes != nodes || oldDelegate.center != center;
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
