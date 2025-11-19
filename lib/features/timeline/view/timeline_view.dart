import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'package:mydearmap/features/memories/views/memory_view.dart';
import 'package:mydearmap/core/constants/constants.dart';

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
          data: (memories) => _TimelineBody(
            memories: memories,
            onDelete: (m) {
              final id = m.id;
              if (id != null) {
                ref.read(userMemoriesCacheProvider.notifier).removeById(id);
              }
              ref.invalidate(userMemoriesProvider);
            },
          ),
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
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset(AppIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
          style: AppButtonStyles.circularIconButton,
        ),
        title: const Text('Timeline'),
      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  dayLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
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
                        content: const Text(
                          '¿Seguro que quieres eliminar este recuerdo?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) onDelete(mem);
                  },
                  onEdit: () {
                    final id = mem.id;
                    if (id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Recuerdo sin id')),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MemoryDetailView(memoryId: id.toString()),
                      ),
                    );
                  },
                  onTap: () {
                    final id = mem.id;
                    if (id == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Recuerdo sin id')),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MemoryDetailView(memoryId: id.toString()),
                      ),
                    );
                  },
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

DateTime _dateOf(Memory m) {
  DateTime? tryParse(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      // > 1e12 => ms, si no => s
      if (v.abs() > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(v);
      }
      return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    if (v is double) {
      final iv = v.toInt();
      if (iv.abs() > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(iv);
      }
      return DateTime.fromMillisecondsSinceEpoch(iv * 1000);
    }
    if (v is String) {
      // intento ISO
      try {
        return DateTime.parse(v);
      } catch (_) {}
      // número en string
      final n = int.tryParse(v);
      if (n != null) {
        if (n.abs() > 1000000000000) {
          return DateTime.fromMillisecondsSinceEpoch(n);
        }
        return DateTime.fromMillisecondsSinceEpoch(n * 1000);
      }
    }
    return null;
  }

  try {
    final dyn = m as dynamic;

    // Si el objeto puede serializarse a Map -> revisar primero (priorizar happened_at)
    Map? asMap;
    if (dyn is Map) {
      asMap = dyn;
    } else {
      try {
        final json = dyn.toJson();
        if (json is Map) asMap = json;
      } catch (_) {}
    }

    if (asMap != null) {
      // priorizar claves que suelen contener la fecha, happened_at primero
      final keys = [
        'happened_at',
        'happenedAt',
        'occurred_at',
        'occurredAt',
        'date',
        'datetime',
        'dateTime',
        'created_at',
        'createdAt',
        'updated_at',
        'timestamp',
        'time',
        'time_ms',
        'timeMs',
        'millisecondsSinceEpoch',
        'secondsSinceEpoch',
      ];
      for (final k in keys) {
        if (!asMap.containsKey(k)) continue;
        final dt = tryParse(asMap[k]);
        if (dt != null) return dt;
      }
    }

    // fallback: intentar acceder dinámicamente a propiedades (por si no hay toJson)
    final candidates = [
      dyn.happened_at,
      dyn.happenedAt,
      dyn.occurred_at,
      dyn.ocurridoAt,
      dyn.date,
      dyn.datetime,
      dyn.dateTime,
      dyn.created_at,
      dyn.createdAt,
      dyn.updated_at,
      dyn.timestamp,
      dyn.time,
      dyn.time_ms,
      dyn.timeMs,
      dyn.millisecondsSinceEpoch,
      dyn.secondsSinceEpoch,
    ];

    for (final c in candidates) {
      final dt = tryParse(c);
      if (dt != null) return dt;
    }
  } catch (_) {
    // ignore y fallback abajo
  }

  // Si nada se parsea correctamente, devuelve ahora para evitar ocultar errores
  // (si sigue ocurriendo, añade un print(memory.toString()) para depurar)
  return DateTime.now();
}

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
  for (final media in m.media) {
    final url = media.url;
    if (url == null || url.isEmpty) continue;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
  }
  try {
    final dyn = m as dynamic;
    final single = dyn.image ?? dyn.photo ?? dyn.picture;
    if (single != null && single.toString().isNotEmpty) {
      return single.toString();
    }
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
    final thumb = _thumbOf(memory);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: SizedBox(
                // uses the row's height; Stack + CustomPaint dibuja la línea discontinua
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DashedLinePainter(
                          color: Colors.grey.shade300,
                          strokeWidth: 2,
                          dashHeight: 6,
                          dashGap: 6,
                          drawTop: !isFirst,
                          drawBottom: !isLast,
                          circleDiameter: 14,
                          circleVerticalGap: 6,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 3),
                        ],
                      ),
                    ),
                  ],
                ),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: FutureBuilder<String?>(
                            future: (thumb != null && thumb.isNotEmpty)
                                ? Future.value(thumb)
                                : _fetchFirstMediaUrl(memory),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              if (snap.hasError) {
                                return const Icon(Icons.broken_image);
                              }
                              final url = snap.data;
                              if (url == null || url.isEmpty) {
                                return const Icon(Icons.photo);
                              }
                              return Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: 72,
                                height: 72,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashHeight;
  final double dashGap;
  final bool drawTop;
  final bool drawBottom;
  final double circleDiameter;
  final double circleVerticalGap;

  _DashedLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashHeight,
    required this.dashGap,
    required this.drawTop,
    required this.drawBottom,
    required this.circleDiameter,
    required this.circleVerticalGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final gap = circleVerticalGap;
    final r = circleDiameter / 2;

    void drawDashed(double startY, double endY) {
      double y = startY;
      while (y < endY) {
        final next = math.min(y + dashHeight, endY);
        canvas.drawLine(Offset(centerX, y), Offset(centerX, next), paint);
        y = next + dashGap;
      }
    }

    if (drawTop) {
      drawDashed(0, centerY - r - gap);
    }
    if (drawBottom) {
      drawDashed(centerY + r + gap, size.height);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) {
    return old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.dashHeight != dashHeight ||
        old.dashGap != dashGap ||
        old.drawTop != drawTop ||
        old.drawBottom != drawBottom ||
        old.circleDiameter != circleDiameter ||
        old.circleVerticalGap != circleVerticalGap;
  }
}

Future<String?> _fetchFirstMediaUrl(Memory m) async {
  try {
    final client = Supabase.instance.client;

    if (m.media.isNotEmpty) {
      for (final media in m.media) {
        final rawUrl = media.url;
        if (rawUrl == null || rawUrl.isEmpty) continue;
        if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
          return rawUrl;
        }
        try {
          final public = client.storage.from('media').getPublicUrl(rawUrl);
          if (public.isNotEmpty) return public;
        } catch (_) {}
      }
    }

    final dyn = m as dynamic;
    final id = dyn.id ?? (dyn is Map ? dyn['id'] : null);
    if (id == null) return null;

    // Pedimos solo el campo 'url' de la tabla media
    final record = await client
        .from('media')
        .select('url')
        .eq('memory_id', id)
        .order('order', ascending: true, nullsFirst: true)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (record == null) return null;

    // Normalizar respuesta
    dynamic data = record;
    if (data is Map && data.containsKey('data')) data = data['data'];
    if (data is List) data = data.isNotEmpty ? data.first : null;
    if (data == null) return null;

    final rawUrl = data['url'] ?? data['Url'] ?? data['URL'];
    if (rawUrl == null) return null;
    final s = rawUrl.toString();
    if (s.isEmpty) return null;

    // Si ya es una URL pública la devolvemos
    if (s.startsWith('http://') || s.startsWith('https://')) return s;

    // Tu bucket se llama 'media' — usamos el path tal cual dentro del bucket
    const bucket = 'media';
    final pathInBucket = s;

    try {
      final pub = client.storage.from(bucket).getPublicUrl(pathInBucket);
      if (pub.isNotEmpty) return pub;
    } catch (_) {
      // getPublicUrl falló; fallback abajo
    }

    // fallback: devuelve el path tal cual (si no funciona, activa un print para depurar)
    return s;
  } catch (e) {
    // opcional: print('fetchFirstMediaUrl error: $e');
    return null;
  }
}
