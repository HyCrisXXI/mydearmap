import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/core/providers/memory_media_provider.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/features/memories/widgets/memory_media_carousel.dart';

class MemoriesOverviewView extends ConsumerWidget {
  const MemoriesOverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(mapMemoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis recuerdos')),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: memoriesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (error, _) => Center(
            child: Text('No se pudieron cargar los recuerdos: $error'),
          ),
          data: (memories) {
            if (memories.isEmpty) {
              return const Center(
                child: Text('Todavía no has guardado ningún recuerdo.'),
              );
            }

            final sorted = [...memories]
              ..sort((a, b) {
                final aDate = _readHappenedAt(a) ?? DateTime(1970);
                final bDate = _readHappenedAt(b) ?? DateTime(1970);
                return bDate.compareTo(aDate);
              });

            return ListView.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSizes.paddingLarge),
              itemBuilder: (context, index) {
                final memory = sorted[index];
                final memoryId = (memory as dynamic).id?.toString() ?? '';

                if (memoryId.isEmpty) {
                  return const _MemoryCardError(
                    message: 'El identificador del recuerdo es inválido.',
                  );
                }

                final isShared = _isSharedMemory(memory);
                final description = _readDescription(memory);
                final happenedAt = _readHappenedAt(memory);
                final locationLabel = _locationLabel(memory);

                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MemoryDetailView(memoryId: memoryId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadius,
                      ),
                    ),
                    color: AppColors.cian,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (memory as dynamic).title?.toString() ??
                                          'Recuerdo sin título',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (happenedAt != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatDate(happenedAt),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Chip(
                                avatar: Icon(
                                  isShared ? Icons.group : Icons.person,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isShared ? 'Compartido' : 'Solo tú',
                                ),
                                backgroundColor: isShared
                                    ? AppColors.primaryColor
                                    : AppColors.accentColor,
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (locationLabel != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: AppColors.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  locationLabel,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppSizes.paddingLarge),
                          Consumer(
                            builder: (context, ref, _) {
                              final mediaAsync = ref.watch(
                                memoryMediaProvider(memoryId),
                              );
                              return mediaAsync.when(
                                loading: () => const SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: CircularProgressIndicator.adaptive(),
                                  ),
                                ),
                                error: (error, _) => _mediaErrorMessage(error),
                                data: (assets) {
                                  if (assets.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: AppSizes.paddingLarge,
                                      ),
                                      MemoryMediaCarousel(
                                        media: assets,
                                        emptyState: const SizedBox.shrink(),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: AppSizes.paddingLarge),
                            Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(height: 1.4),
                            ),
                          ],
                          const SizedBox(height: AppSizes.paddingLarge),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MemoryDetailView(memoryId: memoryId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Ver detalle'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MemoryCardError extends StatelessWidget {
  const _MemoryCardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        color: Colors.redAccent.withValues(alpha: .12),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
      ),
    );
  }
}

bool _isSharedMemory(MapMemory memory) {
  try {
    final participants = (memory as dynamic).participants;
    if (participants is Iterable && participants.length > 1) {
      return true;
    }
  } catch (_) {}
  return false;
}

String _readDescription(MapMemory memory) {
  try {
    final value = (memory as dynamic).description;
    if (value is String) return value;
  } catch (_) {}
  return '';
}

DateTime? _readHappenedAt(MapMemory memory) {
  try {
    final raw = (memory as dynamic).happenedAt;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
  } catch (_) {}
  try {
    final createdAt = (memory as dynamic).createdAt;
    if (createdAt is DateTime) return createdAt;
    if (createdAt is String) return DateTime.tryParse(createdAt);
  } catch (_) {}
  return null;
}

String? _locationLabel(MapMemory memory) {
  dynamic location;
  try {
    location = (memory as dynamic).location;
  } catch (_) {
    return null;
  }
  if (location == null) return null;

  double? lat;
  double? lng;
  try {
    if (location.latitude is num) {
      lat = (location.latitude as num).toDouble();
    }
    if (location.longitude is num) {
      lng = (location.longitude as num).toDouble();
    }
  } catch (_) {
    return null;
  }
  if (lat == null || lng == null) return null;
  return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

Widget _mediaErrorMessage(Object error) {
  final message = error.toString().toLowerCase();
  if (message.contains('permission denied')) {
    return const SizedBox.shrink();
  }
  return Text('Error al cargar archivos: $error');
}
