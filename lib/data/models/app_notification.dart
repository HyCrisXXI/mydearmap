import 'dart:convert';

import 'package:flutter/material.dart';

enum NotificationKind {
  memory,
  relation,
  achievement,
  reminder,
  invite,
  system,
  custom,
}

NotificationKind notificationKindFromString(String? value) {
  switch (value?.toLowerCase().trim()) {
    case 'memory':
    case 'memories':
      return NotificationKind.memory;
    case 'relation':
    case 'relations':
    case 'friend':
      return NotificationKind.relation;
    case 'achievement':
    case 'achievements':
      return NotificationKind.achievement;
    case 'reminder':
    case 'reminders':
      return NotificationKind.reminder;
    case 'invite':
    case 'invitation':
      return NotificationKind.invite;
    case 'system':
    case 'app':
      return NotificationKind.system;
    default:
      return NotificationKind.custom;
  }
}

IconData iconForKind(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.memory:
      return Icons.photo_camera_outlined;
    case NotificationKind.relation:
      return Icons.link_outlined;
    case NotificationKind.achievement:
      return Icons.emoji_events_outlined;
    case NotificationKind.reminder:
      return Icons.alarm_outlined;
    case NotificationKind.invite:
      return Icons.mail_outline;
    case NotificationKind.system:
      return Icons.notifications_active_outlined;
    case NotificationKind.custom:
      return Icons.notifications_none_outlined;
  }
}

class AppNotification {
  final String id;
  final String title;
  final String? message;
  final NotificationKind kind;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? avatarUrl;
  final Map<String, dynamic> metadata;
  final String? actionLabel;

  const AppNotification({
    required this.id,
    required this.title,
    required this.kind,
    required this.createdAt,
    this.message,
    this.isRead = false,
    this.readAt,
    this.avatarUrl,
    this.metadata = const <String, dynamic>{},
    this.actionLabel,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationKind? kind,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
    String? actionLabel,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      kind: kind ?? this.kind,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      metadata: metadata ?? this.metadata,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final createdAtValue =
        map['created_at'] ?? map['createdAt'] ?? map['timestamp'];
    final readAtValue = map['read_at'] ?? map['readAt'];
    final metadataValue = map['metadata'] ?? map['data'];

    return AppNotification(
      id: _stringId(map['id'] ?? map['notification_id'] ?? map['uuid']),
      title:
          _stringOrNull(map['title']) ??
          _stringOrNull(map['summary']) ??
          _stringOrNull(map['event_name']) ??
          _stringOrNull(map['heading']) ??
          _composeTitle(
            actor: _stringOrNull(map['actor_name'] ?? map['actor']),
            action: _stringOrNull(map['action'] ?? map['event_action']),
            target: _stringOrNull(map['entity_name'] ?? map['target_name']),
          ),
      message:
          _stringOrNull(map['message']) ??
          _stringOrNull(map['details']) ??
          _stringOrNull(map['body']) ??
          _stringOrNull(map['description']),
      kind: notificationKindFromString(
        map['type'] ?? map['activity_type'] ?? map['category'] ?? map['kind'],
      ),
      isRead: _boolFrom(map['is_read'] ?? map['read'] ?? map['seen']) ?? false,
      createdAt: _parseDate(createdAtValue),
      readAt: readAtValue == null ? null : _parseDate(readAtValue),
      avatarUrl: _stringOrNull(
        map['avatar_url'] ??
            map['avatarUrl'] ??
            map['image_url'] ??
            map['actor_avatar_url'],
      ),
      metadata: _normalizeMetadata(
        metadataValue,
        additional: {
          if (map['actor_name'] != null)
            'actor_name': _stringOrNull(map['actor_name']) ?? map['actor_name'],
          if (map['entity_name'] != null)
            'entity_name':
                _stringOrNull(map['entity_name']) ?? map['entity_name'],
          if (map['entity_type'] != null) 'entity_type': map['entity_type'],
          if (map['entity_id'] != null) 'entity_id': map['entity_id'],
          if (map['action'] != null) 'action': map['action'],
          if (map['activity_source'] != null)
            'activity_source': map['activity_source'],
        },
      ),
      actionLabel: _stringOrNull(
        map['action_label'] ?? map['cta'] ?? map['button'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': kind.name,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'avatar_url': avatarUrl,
      'metadata': metadata,
      'action_label': actionLabel,
    };
  }
}

String _stringId(dynamic value) {
  if (value == null) {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
  return value.toString();
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

bool? _boolFrom(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return null;
}

DateTime _parseDate(dynamic value) {
  if (value == null) {
    return DateTime.now();
  }
  if (value is DateTime) return value;
  if (value is int) {
    if (value.abs() > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.fromMillisecondsSinceEpoch(value * 1000);
  }
  if (value is double) {
    final asInt = value.toInt();
    if (asInt.abs() > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final numeric = int.tryParse(value);
    if (numeric != null) return _parseDate(numeric);
  }
  return DateTime.now();
}

Map<String, dynamic> _normalizeMetadata(
  dynamic value, {
  Map<String, dynamic>? additional,
}) {
  Map<String, dynamic> base;
  if (value is Map<String, dynamic>) {
    base = Map<String, dynamic>.from(value);
  } else if (value is List) {
    base = {'items': value};
  } else if (value is String) {
    base = _decodeMetadataString(value);
  } else {
    base = <String, dynamic>{};
  }

  if (additional != null) {
    additional.forEach((key, dynamic v) {
      if (v != null) base[key] = v;
    });
  }
  return base;
}

Map<String, dynamic> _decodeMetadataString(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is List) {
      return {'items': decoded};
    }
  } catch (_) {
    // ignore
  }
  return {'value': raw};
}

String _composeTitle({String? actor, String? action, String? target}) {
  final hasActor = actor != null && actor.isNotEmpty;
  final hasAction = action != null && action.isNotEmpty;
  final hasTarget = target != null && target.isNotEmpty;

  if (!hasActor && !hasAction && !hasTarget) {
    return 'Notificación';
  }

  final buffer = StringBuffer();
  if (hasActor) buffer.write(actor);
  if (hasAction) {
    if (buffer.isNotEmpty) buffer.write(' · ');
    buffer.write(action);
  }
  if (hasTarget) {
    buffer.write(hasAction ? ' → ' : ' · ');
    buffer.write(target);
  }
  return buffer.toString();
}
