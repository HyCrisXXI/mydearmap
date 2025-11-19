import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart';
import 'package:mydearmap/core/constants/constants.dart';

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
      Navigator.of(context).pop(true);
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
    if (val is AsyncValue<User?>) {
      final user = val.asData?.value;
      return user?.id;
    }
    if (val is User) return val.id;
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
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(AppIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
          style: AppButtonStyles.circularIconButton,
        ),
        title: const Text('Añadir relación'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
