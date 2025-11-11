import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/memories/controllers/memory_controller.dart';
import 'package:mydearmap/features/memories/views/memory_edit_view.dart';
import 'package:mydearmap/features/memories/widgets/memory_media_carousel.dart';

final memoryDetailProvider = FutureProvider.family<Memory, String>((
  ref,
  memoryId,
) async {
  final controller = ref.read(memoryControllerProvider.notifier);
  final memory = await controller.getMemoryById(memoryId);
  if (memory == null) {
    throw Exception('Recuerdo no disponible');
  }
  return memory;
});

class MemoryDetailView extends ConsumerWidget {
  const MemoryDetailView({required this.memoryId, super.key});

  final String memoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(memoryDetailProvider(memoryId));
    final mapMemoriesAsync = ref.watch(userMemoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del recuerdo'),
        actions: [
          IconButton(
            tooltip: 'Editar recuerdo',
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final refreshed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => MemoryDetailEditView(memoryId: memoryId),
                ),
              );
              if (refreshed == true) {
                ref.invalidate(memoryDetailProvider(memoryId));
                ref.invalidate(memoryMediaProvider(memoryId));
              }
            },
          ),
        ],
      ),
      body: memoryAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) =>
            Center(child: Text('No se pudo cargar el recuerdo: $error')),
        data: (memory) {
          final happenedAt = memory.happenedAt;
          final latLng = _resolveMemoryLocation(memory, mapMemoriesAsync);
          final description = _readDescription(memory);
          final mediaAsync = ref.watch(memoryMediaProvider(memoryId));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(happenedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                mediaAsync.when(
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                  error: (error, _) {
                    final message = error.toString().toLowerCase();
                    if (message.contains('permission denied')) {
                      return const SizedBox.shrink();
                    }
                    return Text('No se pudo cargar la galería: $error');
                  },
                  data: (media) {
                    if (media.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: AppSizes.paddingLarge),
                        child: Text('Todavía no hay archivos adjuntos.'),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSizes.paddingLarge),
                        MemoryMediaCarousel(
                          media: media,
                          prioritizeImages: true,
                          enableFullScreenPreview: true,
                        ),
                      ],
                    );
                  },
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.paddingLarge),
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
                if (memory.participants.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.paddingLarge),
                  Text(
                    'Participantes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Wrap(
                    spacing: AppSizes.paddingSmall,
                    runSpacing: AppSizes.paddingSmall,
                    children: memory.participants.map((ur) {
                      final isCreator = ur.role == MemoryRole.creator;
                      return Chip(
                        avatar: isCreator
                            ? CircleAvatar(
                                backgroundColor: Colors.amber,
                                child: Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                        label: Text(
                          '${ur.user.name}${isCreator ? ' (creador)' : ' (${ur.role.name})'}',
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (latLng != null) ...[
                  const SizedBox(height: AppSizes.paddingLarge),
                  Text(
                    'Ubicación del recuerdo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingMedium),
                  _MemoryLocationMap(point: latLng),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _readDescription(Memory memory) => memory.description?.trim() ?? '';

LatLng? _resolveMemoryLocation(
  Memory memory,
  AsyncValue<List<Memory>> mapMemories,
) {
  final direct = memory.location;
  if (direct != null) {
    return LatLng(direct.latitude, direct.longitude);
  }

  return mapMemories.when(
    data: (memories) {
      for (final candidate in memories) {
        if (candidate.id == memory.id && candidate.location != null) {
          final geo = candidate.location!;
          return LatLng(geo.latitude, geo.longitude);
        }
      }
      return null;
    },
    loading: () => null,
    error: (_, _) => null,
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _MemoryLocationMap extends StatelessWidget {
  const _MemoryLocationMap({required this.point});

  final LatLng point;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate:
                  'https://api.maptiler.com/maps/dataviz/{z}/{x}/{y}.png?key=${EnvConstants.mapTilesApiKey}',
              userAgentPackageName: 'com.mydearmap.app',
              tileProvider: kIsWeb ? NetworkTileProvider() : null,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
