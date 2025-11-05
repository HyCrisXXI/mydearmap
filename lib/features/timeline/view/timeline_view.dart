import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/memory.dart';

class MemoriesTimelineView extends ConsumerWidget {
  const MemoriesTimelineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('No autenticado')));
        final memoriesAsync = ref.watch(memoriesProvider(user.id));
        return memoriesAsync.when(
          loading: () => Scaffold(appBar: AppBar(title: const Text('Timeline')), body: const Center(child: CircularProgressIndicator())),
          error: (e, st) => Scaffold(appBar: AppBar(title: const Text('Timeline')), body: Center(child: Text('Error: $e'))),
          data: (memories) => _TimelineBody(memories: memories, onDelete: (m) {
            // invalidar o llamar al controller según tu arquitectura
            ref.invalidate(memoriesProvider(user.id));
          }),
        );
      },
    );
  }
}

class _TimelineBody extends StatelessWidget {
  final List<Memory> memories;
  final void Function(Memory) onDelete;
  const _TimelineBody({required this.memories, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // orden descendente por fecha (ajusta el campo si es distinto)
    final List<Memory> sorted = List.of(memories)
      ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));

    // agrupar por día
    final DateFormat dayFmt = DateFormat.yMMMMd();
    final Map<String, List<Memory>> grouped = {};
    for (final m in sorted) {
      final key = dayFmt.format(_dateOf(m));
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final groups = grouped.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: groups.length,
        itemBuilder: (context, gi) {
          final dayLabel = groups[gi].key;
          final dayEvents = groups[gi].value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(dayLabel, style: Theme.of(context).textTheme.titleMedium)),
              ...List.generate(dayEvents.length, (i) {
                final mem = dayEvents[i];
                final isFirst = i == 0;
                final isLast = i == dayEvents.length - 1;
                return _TimelineRow(
                  memory: mem,
                  isFirst: isFirst,
                  isLast: isLast,
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Eliminar recuerdo'),
                        content: const Text('¿Seguro que quieres eliminar este recuerdo?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
                        ],
                      ),
                    );
                    if (confirm == true) onDelete(mem);
                  },
                  onEdit: () {
                    // abrir editor: reemplaza por tu vista de edición
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MemoryViewWrapper(memory: mem)));
                  },
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MemoryViewWrapper(memory: mem)));
                  },
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // navegar a crear recuerdo (sustituye por tu view)
        },
      ),
    );
  }
}

// Helpers top-level reutilizables para el timeline (uso dinámico para evitar errores de tipo)
DateTime _dateOf(Memory m) {
  try {
    final dyn = m as dynamic;
    final candidates = [
      dyn.happenedAt,
      dyn.createdAt,
      dyn.date,
      dyn.timestamp,
      dyn.time,
    ];
    for (final c in candidates) {
      if (c == null) continue;
      if (c is DateTime) return c;
      if (c is String) {
        try {
          return DateTime.parse(c);
        } catch (_) {}
      }
      if (c is int) {
        // heurística: distinguir segundos / milisegundos
        if (c > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(c);
        return DateTime.fromMillisecondsSinceEpoch(c * 1000);
      }
    }
  } catch (_) {}
  return DateTime.now();
}

DateTime _timeOf(Memory m) => _dateOf(m);

String? _titleOf(Memory m) {
  try {
    final dyn = m as dynamic;
    final t = dyn.title ?? dyn.name ?? dyn.label ?? dyn.caption;
    if (t == null) return null;
    return t.toString();
  } catch (_) {}
  return null;
}

String? _descriptionOf(Memory m) {
  try {
    final dyn = m as dynamic;
    final d = dyn.description ?? dyn.summary ?? dyn.body ?? dyn.note;
    if (d == null) return null;
    return d.toString();
  } catch (_) {}
  return '';
}

String? _thumbOf(Memory m) {
  try {
    final dyn = m as dynamic;
    final media = dyn.media;
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first == null) return null;
      final url = (first.url ?? first.thumbnailUrl ?? first.path ?? first.src);
      if (url != null && url.toString().isNotEmpty) return url.toString();
    }
    final single = dyn.image ?? dyn.photo ?? dyn.picture;
    if (single != null && single.toString().isNotEmpty) return single.toString();
  } catch (_) {}
  return null;
}

class _TimelineRow extends StatelessWidget {
  final Memory memory;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TimelineRow({
    required this.memory,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = _titleOf(memory) ?? 'Recuerdo';
    final desc = _descriptionOf(memory) ?? '';
    final time = DateFormat.Hm().format(_timeOf(memory));
    final thumb = _thumbOf(memory);

    return Dismissible(
      key: ValueKey(memory.id ?? memory.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        // confirm inside onDelete callback
        onDelete();
        return false; // prevent automatic removal; let onDelete refresh the provider/state
      },
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showActions(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isFirst ? Colors.transparent : Colors.grey.shade300,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLast ? Colors.transparent : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.only(left: 8, right: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey.shade200,
                          child: (thumb != null && thumb.isNotEmpty)
                              ? Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                              : const Icon(Icons.photo),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Text(time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.edit), title: const Text('Editar'), onTap: () {
            Navigator.of(context).pop();
            onEdit();
          }),
          ListTile(leading: const Icon(Icons.delete), title: const Text('Eliminar'), onTap: () {
            Navigator.of(context).pop();
            onDelete();
          }),
          ListTile(leading: const Icon(Icons.close), title: const Text('Cancelar'), onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }

  static DateTime _timeOf(Memory m) {
    // reutiliza _dateOf para consistencia
    return _dateOf(m);
  }

  static String? _titleOf(Memory m) {
    try {
      final dyn = m as dynamic;
      final t = dyn.title ?? dyn.name ?? dyn.label ?? dyn.caption;
      if (t == null) return null;
      return t.toString();
    } catch (_) {}
    return null;
  }

  static String? _descriptionOf(Memory m) {
    try {
      final dyn = m as dynamic;
      final d = dyn.description ?? dyn.summary ?? dyn.body ?? dyn.note;
      if (d == null) return null;
      return d.toString();
    } catch (_) {}
    return '';
  }

  static String? _thumbOf(Memory m) {
    try {
      final dyn = m as dynamic;
      final media = dyn.media;
      if (media is List && media.isNotEmpty) {
        final first = media.first;
        if (first == null) return null;
        final url = (first.url ?? first.thumbnailUrl ?? first.path ?? first.src);
        if (url != null && url.toString().isNotEmpty) return url.toString();
      }
      // fallback single-field image
      final single = dyn.image ?? dyn.photo ?? dyn.picture;
      if (single != null && single.toString().isNotEmpty) return single.toString();
    } catch (_) {}
    return null;
  }
}

/// Simple detail wrapper — reemplaza por tu MemoryView real si quieres.
class MemoryViewWrapper extends StatelessWidget {
  final Memory memory;
  const MemoryViewWrapper({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleOf(memory) ?? 'Detalle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: Text(memory.toString())),
      ),
    );
  }

  static String? _titleOf(Memory m) {
    try {
      if ((m.title ?? '').isNotEmpty) return m.title;
    } catch (_) {}
    return null;
  }
  
}