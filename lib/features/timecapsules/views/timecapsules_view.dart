import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/timecapsule_provider.dart';
import 'timecapsule_view.dart';
import 'timecapsule_create_view.dart';
import 'package:mydearmap/core/constants/constants.dart';

class TimeCapsulesView extends ConsumerWidget {
  const TimeCapsulesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capsulesAsync = ref.watch(userTimeCapsulesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(AppIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
          style: AppButtonStyles.circularIconButton,
        ),
        title: const Text('Mis Cápsulas de Tiempo'),
        actions: [
          IconButton(
            icon: Image.asset(AppIcons.plus),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TimeCapsuleCreateView(),
                ),
              );
            },
            style: AppButtonStyles.circularIconButton,
          ),
        ],
      ),
      body: capsulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (capsules) => capsules.isEmpty
            ? const Center(child: Text('No tienes cápsulas de tiempo.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: capsules.length,
                itemBuilder: (context, index) {
                  final capsule = capsules[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(capsule.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (capsule.description != null)
                            Text(capsule.description!),
                          Text('Días para abrir: ${capsule.daysUntilOpen}'),
                          Text(capsule.isClosed ? 'Cerrada' : 'Abierta'),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                TimeCapsuleView(capsuleId: capsule.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
