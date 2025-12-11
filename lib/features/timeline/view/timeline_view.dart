import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/media.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'dart:math' as math;
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/utils/media_url.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MemoriesTimelineView extends ConsumerWidget {
  const MemoriesTimelineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('No autenticado')));
        }
        final memoriesAsync = ref.watch(userMemoriesProvider);
        return memoriesAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Timeline')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Scaffold(
            appBar: AppBar(title: const Text('Timeline')),
            body: Center(child: Text('Error: $e')),
          ),
          data: (memories) => _TimelineBody(memories: memories),
        );
      },
    );
  }
}

class _TimelineBody extends StatelessWidget {
  final List<Memory> memories;
  const _TimelineBody({required this.memories});

  @override
  Widget build(BuildContext context) {
    final events = List.of(memories)
      ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Custom Header matching RelationsView
            Padding(
              padding: const EdgeInsets.only(
                top: AppSizes.upperPadding,
                bottom: 8.0,
                left: 16,
                right: 30.0,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: SvgPicture.asset(AppIcons.chevronLeft),
                      onPressed: () => Navigator.of(context).pop(),
                      style: AppButtonStyles.circularIconButton,
                    ),
                  ),
                  const Text('Timeline', style: AppTextStyles.title),
                ],
              ),
            ),
            // Content
            Expanded(
              child: events.isEmpty
                  ? const _TimelineEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final memory = events[index];
                        final alignLeft = index.isEven;
                        final isFirst = index == 0;
                        final isLast = index == events.length - 1;
                        return _TimelineEventTile(
                          memory: memory,
                          alignLeft: alignLeft,
                          isFirst: isFirst,
                          isLast: isLast,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _titleOf(Memory memory) {
  final raw = memory.title.trim();
  return raw.isEmpty ? null : raw;
}

String? _descriptionOf(Memory memory) {
  final desc = memory.description?.trim();
  if (desc == null || desc.isEmpty) return null;
  return desc;
}

DateTime _dateOf(Memory memory) => memory.happenedAt;

class _TimelineEventTile extends StatelessWidget {
  final Memory memory;
  final bool alignLeft;
  final bool isFirst;
  final bool isLast;

  const _TimelineEventTile({
    required this.memory,
    required this.alignLeft,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: alignLeft
                  ? _TimelineEventCard(memory: memory, alignRight: true)
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: 70,
              child: _TimelineConnector(isFirst: isFirst, isLast: isLast),
            ),
            Expanded(
              child: alignLeft
                  ? const SizedBox.shrink()
                  : _TimelineEventCard(memory: memory, alignRight: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEventCard extends StatelessWidget {
  final Memory memory;
  final bool alignRight;

  const _TimelineEventCard({required this.memory, required this.alignRight});

  @override
  Widget build(BuildContext context) {
    final title = _titleOf(memory) ?? 'Recuerdo';
    final desc = _descriptionOf(memory);
    final dateLabel = DateFormat('d MMM y', 'es_ES').format(_dateOf(memory));
    final colorScheme = Theme.of(context).colorScheme;
    final coverUrl = _coverUrlFor(memory);

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openMemoryDetail(context, memory),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
            // Shadow removed as requested
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignRight
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: coverUrl != null
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _TimelineImagePlaceholder(),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : const _TimelineImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                dateLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: alignRight ? TextAlign.right : TextAlign.left,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (desc != null) ...[
                const SizedBox(height: 8),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: alignRight ? TextAlign.right : TextAlign.left,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade800),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final bool isFirst;
  final bool isLast;

  const _TimelineConnector({required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CenterLinePainter(isFirst: isFirst, isLast: isLast),
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CenterLinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;

  const _CenterLinePainter({required this.isFirst, required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    const double dashHeight = 10;
    const double dashGap = 6;
    const double nodeClearance = 22;

    void drawRange(double startY, double endY) {
      double y = startY;
      while (y < endY) {
        final next = math.min(y + dashHeight, endY);
        canvas.drawLine(Offset(centerX, y), Offset(centerX, next), paint);
        y = next + dashGap;
      }
    }

    if (!isFirst) {
      drawRange(0, size.height / 2 - nodeClearance);
    }
    if (!isLast) {
      drawRange(size.height / 2 + nodeClearance, size.height);
    }
  }

  @override
  bool shouldRepaint(covariant _CenterLinePainter oldDelegate) {
    return oldDelegate.isFirst != isFirst || oldDelegate.isLast != isLast;
  }
}

class _TimelineEmptyState extends StatelessWidget {
  const _TimelineEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timeline_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Tu timeline está vacío',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Guarda recuerdos para verlos aquí en orden cronológico.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

void _openMemoryDetail(BuildContext context, Memory memory) {
  final id = memory.id;
  if (id == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recuerdo sin id')));
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MemoryDetailView(memoryId: id.toString()),
    ),
  );
}

String? _coverUrlFor(Memory memory) {
  for (final media in memory.media) {
    final url = media.url;
    if (media.type == MediaType.image && url != null && url.isNotEmpty) {
      if (!_looksLikeImage(url)) continue;
      return buildMediaPublicUrl(url);
    }
  }
  return null;
}

bool _looksLikeImage(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif');
}

class _TimelineImagePlaceholder extends StatelessWidget {
  const _TimelineImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.photo, color: Colors.grey.shade500, size: 32),
    );
  }
}
