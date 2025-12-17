import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/features/relations/controllers/relations_controller.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/widgets/pulse_button.dart';

class RelationCreateView extends ConsumerStatefulWidget {
  const RelationCreateView({super.key});

  @override
  RelationCreateViewState createState() => RelationCreateViewState();
}

class RelationCreateViewState extends ConsumerState<RelationCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  bool _loading = false;
  String? _selectedUserId;
  List<User> _suggestions = [];

  @override
  void dispose() {
    _userController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final client = Supabase.instance.client;
    final currentUserId = _currentUserIdFromRef(ref);
    final response = await client
        .from('users')
        .select('id, name, email, profile_url')
        .ilike('name', '%$query%')
        .limit(10);
    final emailMatches = await client
        .from('users')
        .select('id, name, email, profile_url')
        .ilike('email', '%$query%')
        .limit(10);

    final all = [...response as List, ...emailMatches as List];
    final seen = <String>{};
    final users = all
        .map((e) => User.fromMap(Map<String, dynamic>.from(e)))
        .where((u) => u.id != currentUserId)
        .where((u) => seen.add(u.id))
        .toList();
    setState(() => _suggestions = users);
  }

  Future<void> _submit() async {
    if (_selectedUserId == null || _selectedUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un usuario válido')),
      );
      return;
    }
    final currentUserId = _currentUserIdFromRef(ref);
    if (currentUserId == null || currentUserId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actual no disponible')),
        );
      }
      return;
    }
    if (_selectedUserId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes crear un vínculo contigo mismo'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(relationControllerProvider.notifier)
          .createRelation(
            currentUserId: currentUserId,
            relatedUserIdentifier: _selectedUserId!,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vínculo añadido correctamente')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al añadir el vínculo: $e')));
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
        leading: PulseButton(
          child: IconButton(
            icon: SvgPicture.asset(AppIcons.chevronLeft),
            onPressed: () => Navigator.of(context).pop(),
            style: AppButtonStyles.circularIconButton,
          ),
        ),
        title: const Text('Añadir vínculo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Autocomplete<User>(
                displayStringForOption: (u) => '${u.name} (${u.email})',
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  await _fetchSuggestions(textEditingValue.text);
                  return _suggestions;
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      _userController.value = controller.value;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Usuario (nombre o email)',
                          hintText: 'Busca por nombre o email',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(AppIcons.userRound),
                          ),
                        ),
                        validator: (v) =>
                            (_selectedUserId == null ||
                                _selectedUserId!.isEmpty)
                            ? 'Selecciona un usuario de la lista'
                            : null,
                      );
                    },
                onSelected: (User selection) {
                  _selectedUserId = selection.id;
                  _userController.text =
                      '${selection.name} (${selection.email})';
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        height: 220,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final user = options.elementAt(index);
                            return ListTile(
                              leading: user.profileUrl != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        user.profileUrl!,
                                      ),
                                    )
                                  : CircleAvatar(
                                      child: SvgPicture.asset(
                                        AppIcons.userRound,
                                        width: 24,
                                        height: 24,
                                      ),
                                    ),
                              title: Text(user.name),
                              subtitle: Text(user.email),
                              onTap: () {
                                onSelected(user);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
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
                      : SvgPicture.asset(
                          AppIcons.check,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                  label: Text(_loading ? 'Guardando...' : 'Guardar vínculo'),
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
