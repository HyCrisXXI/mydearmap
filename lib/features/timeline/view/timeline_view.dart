import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timelines/timelines.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';

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
          data: (memories) => _buildTimeline(context, memories),
        );
      },
    );
  }

  Widget _buildTimeline(BuildContext context, List<Memory> memories) {
    // ordenar por happenedAt descendente (más reciente primero)
    final List<Memory> sorted = List.of(memories)..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));

    // agrupar por día respetando el orden
    final Map<String, List<Memory>> grouped = {};
    final DateFormat dayFmt = DateFormat.yMMMMd();
    for (final m in sorted) {
      final key = dayFmt.format(m.happenedAt);
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
                child: Text(dayLabel, style: Theme.of(context).textTheme.titleMedium),
              ),
              ...List.generate(dayEvents.length, (i) {
                final mem = dayEvents[i];
                final bool isFirst = gi == 0 && i == 0;
                final bool isLast = gi == groups.length - 1 && i == dayEvents.length - 1;
                return FixedTimeline.tileBuilder(
  builder: TimelineTileBuilder.connected(
    connectionDirection: ConnectionDirection.after,
    itemCount: sorted.length,
    contentsBuilder: (context, index) {
      final mem = sorted[index];
      return GestureDetector(
        onTap: () {
          if (mem.id != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => MemoryDetailView(memoryId: mem.id!)));
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(leading: const Icon(Icons.edit), title: const Text('Editar'), onTap: () {/* editar */}),
                ListTile(leading: const Icon(Icons.delete), title: const Text('Eliminar'), onTap: () {/* eliminar */}),
                ListTile(leading: const Icon(Icons.close), title: const Text('Cancelar'), onTap: () => Navigator.pop(context)),
              ]),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey.shade200,
                  child: (mem.media.isNotEmpty && (mem.media.first.url?.isNotEmpty ?? false))
                      ? Image.network(mem.media.first.url!, fit: BoxFit.cover)
                      : const Icon(Icons.photo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(mem.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(mem.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(DateFormat.Hm().format(mem.happenedAt), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      );
    },
    indicatorBuilder: (context, index) => const DotIndicator(color: Colors.blueAccent),
    connectorBuilder: (context, index, type) => const SolidLineConnector(color: Colors.grey),
  ),
);
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // navegar a crear recuerdo
        },
      ),
    );
  }
}