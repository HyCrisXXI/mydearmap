import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'timecapsule_create_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/widgets/pulse_button.dart';

class TimeCapsuleView extends ConsumerWidget {
  const TimeCapsuleView({super.key, required this.capsuleId});

  final String capsuleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsuleAsync = ref.watch(timeCapsuleProvider(capsuleId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushReplacementNamed('/notifications');
            }
          },
        ),
        title: const Text('Detalle de Cápsula'),
        actions: [
          PulseButton(
            child: IconButton(
              icon: SvgPicture.asset(AppIcons.pencil),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TimeCapsuleCreateView(capsuleId: capsuleId),
                  ),
                );
              },
              style: AppButtonStyles.circularIconButton,
            ),
          ),
        ],
      ),
      body: capsuleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (capsule) {
          if (capsule == null) {
            return const Center(child: Text('Cápsula no encontrada'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capsule.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (capsule.description != null) ...[
                  const SizedBox(height: 8),
                  Text(capsule.description!),
                ],
                const SizedBox(height: 16),
                Text('Estado: ${capsule.isClosed ? 'Cerrada' : 'Abierta'}'),
                const SizedBox(height: 16),
                const Text(
                  'Recuerdos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                capsule.isClosed
                    ? _ClosedMemoriesList(capsuleId: capsuleId)
                    : _OpenMemoriesList(capsuleId: capsuleId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClosedMemoriesList extends ConsumerWidget {
  const _ClosedMemoriesList({required this.capsuleId});

  final String capsuleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(timeCapsuleRepositoryProvider);
    return FutureBuilder<List<String>>(
      future: repo.getTimeCapsuleMemoryTitles(capsuleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        final titles = snapshot.data ?? [];
        return Column(
          children: titles
              .map((title) => ListTile(title: Text(title)))
              .toList(),
        );
      },
    );
  }
}

class _OpenMemoriesList extends ConsumerWidget {
  const _OpenMemoriesList({required this.capsuleId});

  final String capsuleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(timeCapsuleRepositoryProvider);
    return FutureBuilder<List<Memory>>(
      future: repo.getTimeCapsuleMemories(capsuleId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
        final memories = snapshot.data ?? [];
        return Column(
          children: memories
              .map(
                (memory) => ListTile(
                  title: Text(memory.title),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MemoryDetailView(memoryId: memory.id!),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }
}
