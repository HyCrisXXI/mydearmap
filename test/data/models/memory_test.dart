import 'package:flutter_test/flutter_test.dart';
import 'package:mydearmap/data/models/memory.dart';

void main() {
  group('Memory Model Tests', () {
    final fixedDate = DateTime(2023, 1, 1, 12, 0, 0);
    final fixedDateIso = fixedDate.toIso8601String();

    test('fromJson creates a valid Memory instance with full data', () {
      final json = {
        'id': 'mem-123',
        'title': 'Test Memory',
        'description': 'A description',
        'location': 'POINT(10.0 20.0)',
        'happened_at': fixedDateIso,
        'created_at': fixedDateIso,
        'updated_at': fixedDateIso,
        'favorite': true,
        'current_user_role': 'creator',
        'participants': [
          {
            'user': {
              'id': 'user-1',
              'name': 'Alice',
              'email': 'alice@example.com',
              'gender': 'female',
              'created_at': fixedDateIso,
            },
            'role': 'participant',
          },
        ],
        'media': [
          {
            'id': 'media-1',
            'type': 'image',
            'url': 'http://example.com/image.jpg',
            'created_at': fixedDateIso,
          },
        ],
        'comments': [
          {
            'id': 1,
            'content': 'Nice!',
            'created_at': fixedDateIso,
            'updated_at': fixedDateIso,
            'user': {
              'id': 'user-2',
              'name': 'Bob',
              'email': 'bob@example.com',
              'gender': 'male',
              'created_at': fixedDateIso,
            },
          },
        ],
        'reactions': [
          {
            'id': 1,
            'reaction_type': 'like',
            'created_at': fixedDateIso,
            'user': {
              'id': 'user-3',
              'name': 'Charlie',
              'email': 'charlie@example.com',
              'gender': 'other',
              'created_at': fixedDateIso,
            },
          },
        ],
      };

      final memory = Memory.fromJson(json);

      expect(memory.id, 'mem-123');
      expect(memory.title, 'Test Memory');
      expect(memory.description, 'A description');
      expect(memory.location?.latitude, 20.0);
      expect(memory.location?.longitude, 10.0);
      expect(memory.happenedAt, fixedDate);
      expect(memory.isFavorite, true);
      expect(memory.currentUserRole, MemoryRole.creator);

      expect(memory.participants.length, 1);
      expect(memory.participants.first.role, MemoryRole.participant);
      expect(memory.participants.first.user.id, 'user-1');

      expect(memory.media.length, 1);
      expect(memory.media.first.id, 'media-1');

      expect(memory.comments.length, 1);
      expect(memory.comments.first.content, 'Nice!');

      expect(memory.reactions.length, 1);
      expect(memory.reactions.first.reactionType, 'like');
    });

    test('fromJson handles null/missing optional fields', () {
      final json = {
        'title': 'Minimal Memory',
        'happened_at': fixedDateIso,
        'created_at': fixedDateIso,
        'updated_at': fixedDateIso,
      };

      final memory = Memory.fromJson(json);

      expect(memory.title, 'Minimal Memory');
      expect(memory.id, null);
      expect(memory.description, null);
      expect(memory.location, null);
      expect(memory.isFavorite, false);
      expect(memory.currentUserRole, null);
      expect(memory.participants, isEmpty);
      expect(memory.media, isEmpty);
      expect(memory.comments, isEmpty);
      expect(memory.reactions, isEmpty);
    });

    test('toJson serializes correctly', () {
      final memory = Memory(
        id: 'mem-1',
        title: 'Serialized Memory',
        description: 'Desc',
        location: GeoPoint(20.0, 10.0),
        happenedAt: fixedDate,
        createdAt: fixedDate,
        updatedAt: fixedDate,
        isFavorite: true,
      );

      final json = memory.toJson();

      expect(json['title'], 'Serialized Memory');
      expect(json['description'], 'Desc');
      expect(json['location'], 'POINT(10.0 20.0)');
      expect(json['happened_at'], fixedDateIso);
      expect(json['favorite'], true);

      expect(json.containsKey('participants'), false);
      expect(json.containsKey('media'), false);
      expect(json.containsKey('comments'), false);
      expect(json.containsKey('reactions'), false);
      expect(json.containsKey('id'), false);
    });

    group('GeoPoint Parsing', () {
      test('parses WKT POINT', () {
        final pt = GeoPoint.tryParse('POINT(10.5 20.5)');
        expect(pt?.longitude, 10.5);
        expect(pt?.latitude, 20.5);
      });

      test('parses GeoJSON map', () {
        final pt = GeoPoint.tryParse({
          'type': 'Point',
          'coordinates': [10.5, 20.5],
        });
        expect(pt?.longitude, 10.5);
        expect(pt?.latitude, 20.5);
      });

      test('parses WKB Hex String (Legacy PostGIS format)', () {
        // Hexadecimal real para POINT(1.0 1.0) en Little Endian
        const wkbHex = '0101000000000000000000F03F000000000000F03F';
        final pt = GeoPoint.tryParse(wkbHex);

        expect(pt, isNotNull);
        expect(pt?.longitude, 1.0); // Nota: WKB suele ser Lon/Lat
        expect(pt?.latitude, 1.0);
      });

      test('returns null for invalid input', () {
        expect(GeoPoint.tryParse(null), null);
        expect(GeoPoint.tryParse('INVALID'), null);
      });
    });
  });
}
