import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoriesOverviewView extends ConsumerWidget {
  const MemoriesOverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoriesAsync = ref.watch(userMemoriesProvider);

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
              ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));

            return ListView.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSizes.paddingLarge),
              itemBuilder: (context, index) {
                final memory = sorted[index];
                final memoryId = memory.id ?? '';

                if (memoryId.isEmpty) {
                  return const _MemoryCardError(
                    message: 'El identificador del recuerdo es inválido.',
                  );
                }

                return _MemoryListItem(
                  memory: memory,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MemoryDetailView(memoryId: memoryId),
                      ),
                    );
                  },
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

String _readDescription(Memory memory) => memory.description?.trim() ?? '';

class _MemoryListItem extends StatelessWidget {
  const _MemoryListItem({required this.memory, required this.onTap});

  final Memory memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = _readDescription(memory);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PrimaryMediaPreview(memory: memory),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryMediaPreview extends StatelessWidget {
  const _PrimaryMediaPreview({required this.memory});

  final Memory memory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<String?>(
          future: _primaryMediaUrl(memory),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (snapshot.hasError) {
              return const Icon(Icons.broken_image);
            }

            final url = snapshot.data;
            if (url == null || url.isEmpty) {
              return const Icon(Icons.photo, size: 32);
            }

            return Image.network(
              url,
              fit: BoxFit.cover,
              width: 96,
              height: 96,
              errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
            );
          },
        ),
      ),
    );
  }
}

Future<String?> _primaryMediaUrl(Memory memory) async {
  final client = Supabase.instance.client;

  String? toPublicUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    try {
      final public = client.storage.from('media').getPublicUrl(raw);
      if (public.isNotEmpty) return public;
    } catch (_) {}
    return raw.isNotEmpty ? raw : null;
  }

  for (final media in memory.media) {
    if (media.type == MediaType.image) {
      final rawUrl = media.url;
      if (rawUrl == null || rawUrl.isEmpty) continue;
      final resolved = toPublicUrl(rawUrl);
      if (resolved != null) return resolved;
    }
  }

  for (final media in memory.media) {
    final rawUrl = media.url;
    if (rawUrl == null || rawUrl.isEmpty) continue;
    final resolved = toPublicUrl(rawUrl);
    if (resolved != null) return resolved;
  }

  final id = memory.id;
  if (id == null || id.isEmpty) return null;

  try {
    final record = await client
        .from('media')
        .select('url, media_type')
        .eq('memory_id', id)
        .order('order', ascending: true, nullsFirst: true)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (record == null) return null;

    dynamic payload = record;
    if (payload is Map && payload.containsKey('data')) {
      payload = payload['data'];
    }
    if (payload is List && payload.isNotEmpty) {
      payload = payload.first;
    }
    if (payload == null) return null;

    String? extractUrl(dynamic value) {
      if (value is Map) {
        final urlValue = value['url'] ?? value['Url'] ?? value['URL'];
        if (urlValue is String) return urlValue;
      }
      if (value is String) return value;
      return null;
    }

    final url = extractUrl(payload);
    if (url == null || url.isEmpty) return null;
    return toPublicUrl(url);
  } catch (_) {
    return null;
  }
}
