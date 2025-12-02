import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/core/utils/avatar_url.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/models/user.dart';
import 'package:mydearmap/data/models/user_relation.dart';

class MemoryFilterZone {
  final LatLng center;
  final double radiusMeters;
  final String label;

  const MemoryFilterZone({
    required this.center,
    required this.radiusMeters,
    required this.label,
  });

  MemoryFilterZone copyWith({
    LatLng? center,
    double? radiusMeters,
    String? label,
  }) {
    return MemoryFilterZone(
      center: center ?? this.center,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      label: label ?? this.label,
    );
  }
}

class FilterUserOption {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final List<String> relationLabels;

  const FilterUserOption({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.relationLabels = const [],
  });

  FilterUserOption copyWith({
    String? displayName,
    String? avatarUrl,
    List<String>? relationLabels,
  }) => FilterUserOption(
    userId: userId,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    relationLabels: relationLabels ?? this.relationLabels,
  );

  bool get hasRelation => relationLabels.isNotEmpty;
}

class MemoryFilterCriteria {
  final Set<String> userIds;
  final DateTimeRange? dateRange;
  final MemoryFilterZone? zone;

  const MemoryFilterCriteria({
    this.userIds = const {},
    this.dateRange,
    this.zone,
  });

  static const MemoryFilterCriteria empty = MemoryFilterCriteria();

  bool get hasFilters =>
      userIds.isNotEmpty || dateRange != null || zone != null;

  MemoryFilterCriteria copyWith({
    Set<String>? userIds,
    DateTimeRange? dateRange,
    MemoryFilterZone? zone,
  }) => MemoryFilterCriteria(
    userIds: userIds ?? this.userIds,
    dateRange: dateRange ?? this.dateRange,
    zone: zone ?? this.zone,
  );
}

class MemoryFilterUtils {
  static List<Memory> applyFilters(
    List<Memory> memories,
    MemoryFilterCriteria criteria,
  ) {
    if (!criteria.hasFilters) return memories;
    final distance = Distance();

    return memories.where((memory) {
      if (criteria.userIds.isNotEmpty &&
          !_memoryContainsAnyUser(memory, criteria.userIds)) {
        return false;
      }

      final range = criteria.dateRange;
      if (range != null) {
        final date = memory.happenedAt;
        if (date.isBefore(range.start) || date.isAfter(range.end)) {
          return false;
        }
      }

      final zone = criteria.zone;
      if (zone != null) {
        final location = memory.location;
        if (location == null) return false;
        final dist = distance(
          LatLng(location.latitude, location.longitude),
          zone.center,
        );
        if (dist > zone.radiusMeters) return false;
      }

      return true;
    }).toList();
  }

  static List<FilterUserOption> buildUserOptions({
    required List<Memory> memories,
    required User? currentUser,
    required List<UserRelation> relations,
  }) {
    final map = <String, FilterUserOption>{};

    void upsert(User user, {String? relationLabel}) {
      if (user.id.isEmpty) return;
      if (currentUser != null && user.id == currentUser.id) return;
      final display = user.name.trim().isNotEmpty
          ? user.name.trim()
          : user.email.trim();
      final normalizedName = display.isEmpty ? 'Usuario' : display;
      final avatar = buildAvatarUrl(user.profileUrl);
      final existing = map[user.id];
      final labels = <String>[if (existing != null) ...existing.relationLabels];
      final normalizedLabel = relationLabel?.trim();
      if (normalizedLabel != null &&
          normalizedLabel.isNotEmpty &&
          !labels.contains(normalizedLabel)) {
        labels.add(normalizedLabel);
      }

      map[user.id] = FilterUserOption(
        userId: user.id,
        displayName: normalizedName,
        avatarUrl: avatar,
        relationLabels: labels,
      );
    }

    for (final memory in memories) {
      for (final participant in memory.participants) {
        upsert(participant.user);
      }
      final owner = _tryResolveOwner(memory);
      if (owner != null) upsert(owner);
    }

    for (final relation in relations) {
      upsert(relation.relatedUser, relationLabel: _relationLabel(relation));
    }

    final list = map.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  static List<String> describeCriteria({
    required MemoryFilterCriteria criteria,
    List<FilterUserOption> userOptions = const [],
  }) {
    final labels = <String>[];

    if (criteria.userIds.isNotEmpty) {
      final mapped = userOptions
          .where((option) => criteria.userIds.contains(option.userId))
          .map(
            (option) => option.hasRelation
                ? '${option.displayName} (${option.relationLabels.first})'
                : option.displayName,
          )
          .toList();
      labels.addAll(
        mapped.isNotEmpty ? mapped : const ['Usuarios seleccionados'],
      );
    }

    final range = criteria.dateRange;
    if (range != null) {
      labels.add('${_formatDate(range.start)} - ${_formatDate(range.end)}');
    }

    if (criteria.zone != null) {
      labels.add(criteria.zone!.label);
    }

    return labels;
  }

  static String _relationLabel(UserRelation relation) {
    final json = _relationJson(relation);
    final candidates = [
      json?['label'],
      json?['relationLabel'],
      json?['relation_name'],
      json?['relationType'],
      json?['relationship'],
      json?['relationshipType'],
      json?['type'],
    ];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return 'Vínculo';
  }

  static Map<String, dynamic>? _relationJson(UserRelation relation) {
    try {
      final dynamic result = (relation as dynamic).toJson();
      if (result is Map<String, dynamic>) return result;
    } catch (_) {}
    return null;
  }

  static User? _tryResolveOwner(Memory memory) {
    try {
      final owner = (memory as dynamic).owner as User?;
      return owner;
    } catch (_) {
      return null;
    }
  }

  static bool _memoryContainsAnyUser(Memory memory, Set<String> userIds) {
    if (userIds.isEmpty) return true;

    for (final participant in memory.participants) {
      if (userIds.contains(participant.user.id)) return true;
    }

    try {
      final ownerId = (memory as dynamic).ownerId as String?;
      if (ownerId != null && userIds.contains(ownerId)) return true;
    } catch (_) {}

    try {
      final creatorId = (memory as dynamic).createdBy as String?;
      if (creatorId != null && userIds.contains(creatorId)) return true;
    } catch (_) {}

    return false;
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

Future<MemoryFilterCriteria?> showMemoryFiltersSheet({
  required BuildContext context,
  required MemoryFilterCriteria initialCriteria,
  required List<FilterUserOption> userOptions,
  LatLng? suggestedZoneCenter,
}) {
  final selectedUserIds = initialCriteria.userIds.toSet();
  DateTimeRange? dateRange = initialCriteria.dateRange;
  MemoryFilterZone? zone = initialCriteria.zone;
  LatLng? zoneCenter = zone?.center;
  bool zoneActive = zoneCenter != null;
  double radiusMeters = zone?.radiusMeters ?? 1000;
  final zoneController = TextEditingController(text: zone?.label ?? '');
  List<_ZoneSuggestion> zoneSuggestions = const [];

  Future<void> searchZones(
    String query,
    void Function(void Function()) setState,
  ) async {
    zoneSuggestions = await _fetchZoneSuggestions(query);
    setState(() {});
  }

  return showModalBottomSheet<MemoryFilterCriteria>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (modalContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filtros de recuerdos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedUserIds.clear();
                            dateRange = null;
                            zone = null;
                            zoneActive = false;
                            zoneCenter = null;
                            radiusMeters = 1000;
                            zoneController.clear();
                            zoneSuggestions = const [];
                          });
                        },
                        child: const Text('Limpiar todo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (userOptions.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vínculos',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(right: 8),
                            physics: const BouncingScrollPhysics(),
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemCount: userOptions.length,
                            itemBuilder: (context, index) {
                              final option = userOptions[index];
                              final selected = selectedUserIds.contains(
                                option.userId,
                              );
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      selectedUserIds.remove(option.userId);
                                    } else {
                                      selectedUserIds.add(option.userId);
                                    }
                                  });
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: option.avatarUrl != null
                                          ? AppDecorations.profileAvatar(
                                              NetworkImage(option.avatarUrl!),
                                            )
                                          : const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black12,
                                            ),
                                      foregroundDecoration: selected
                                          ? BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.accentColor,
                                                width: 3,
                                              ),
                                            )
                                          : null,
                                      child: option.avatarUrl == null
                                          ? Center(
                                              child: Text(
                                                option.displayName.isNotEmpty
                                                    ? option.displayName[0]
                                                          .toUpperCase()
                                                    : '?',
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        option.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selected
                                              ? AppColors.accentColor
                                              : AppColors.textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Rango de fechas'),
                    subtitle: Text(
                      dateRange == null
                          ? 'Selecciona un rango'
                          : '${MemoryFilterUtils._formatDate(dateRange!.start)} • ${MemoryFilterUtils._formatDate(dateRange!.end)}',
                    ),
                    trailing: const Icon(Icons.date_range),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        initialDateRange: dateRange,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => dateRange = picked);
                      }
                    },
                  ),
                  if (dateRange != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(() => dateRange = null),
                        child: const Text('Quitar rango'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Zona',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: zoneController,
                    decoration: InputDecoration(
                      hintText: 'Buscar lugar o escribir etiqueta',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () =>
                            searchZones(zoneController.text, setState),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.trim().length >= 3) {
                        searchZones(value, setState);
                      } else {
                        setState(() => zoneSuggestions = const []);
                      }
                    },
                    onTap: () => setState(() => zoneActive = true),
                  ),
                  if (zoneSuggestions.isNotEmpty)
                    ...zoneSuggestions.map(
                      (suggestion) => ListTile(
                        title: Text(suggestion.name),
                        onTap: () {
                          setState(() {
                            zoneCenter = suggestion.center;
                            zoneActive = true;
                            zoneController.text = suggestion.name;
                            zoneSuggestions = const [];
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (zoneActive && zoneCenter != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radio: ${(radiusMeters / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Slider(
                          min: 200,
                          max: 5000,
                          divisions: 24,
                          label:
                              '${(radiusMeters / 1000).toStringAsFixed(1)} km',
                          value: radiusMeters,
                          onChanged: (value) =>
                              setState(() => radiusMeters = value),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                zoneActive = false;
                                zoneCenter = null;
                                zone = null;
                                radiusMeters = 1000;
                                zoneController.clear();
                                zoneSuggestions = const [];
                              });
                            },
                            child: const Text('Quitar zona'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          MemoryFilterZone? finalZone;
                          if (zoneActive && zoneCenter != null) {
                            finalZone = MemoryFilterZone(
                              center: zoneCenter!,
                              radiusMeters: radiusMeters,
                              label: zoneController.text.trim().isNotEmpty
                                  ? zoneController.text.trim()
                                  : 'Zona personalizada',
                            );
                          }
                          Navigator.of(context).pop(
                            MemoryFilterCriteria(
                              userIds: selectedUserIds,
                              dateRange: dateRange,
                              zone: finalZone,
                            ),
                          );
                        },
                        child: const Text('Aplicar filtros'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _ZoneSuggestion {
  final String name;
  final LatLng center;

  const _ZoneSuggestion(this.name, this.center);
}

Future<List<_ZoneSuggestion>> _fetchZoneSuggestions(String query) async {
  final trimmed = query.trim();
  if (trimmed.length < 3) return const [];
  final url = Uri.parse(
    'https://api.maptiler.com/geocoding/${Uri.encodeComponent(trimmed)}.json?autocomplete=true&key=${EnvConstants.mapTilesApiKey}',
  );
  try {
    final response = await http.get(url);
    if (response.statusCode != 200) return const [];
    final data = json.decode(response.body) as Map<String, dynamic>;
    final features = data['features'] as List<dynamic>? ?? const [];
    return features.map((feature) {
      final f = feature as Map<String, dynamic>;
      final coords = f['geometry']['coordinates'] as List<dynamic>;
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      final name = (f['place_name'] ?? f['text'] ?? trimmed).toString();
      return _ZoneSuggestion(name, LatLng(lat, lng));
    }).toList();
  } catch (_) {
    return const [];
  }
}
