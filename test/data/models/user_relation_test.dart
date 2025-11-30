import 'package:flutter_test/flutter_test.dart';
import 'package:mydearmap/data/models/user_relation.dart';

void main() {
  group('UserRelation Model Tests', () {
    final fixedDate = DateTime(2023, 1, 1, 12, 0, 0);
    final fixedDateIso = fixedDate.toIso8601String();

    test('fromMapWithRelated creates valid UserRelation with full objects', () {
      final map = {
        'user': {
          'id': 'user-1',
          'name': 'Alice',
          'email': 'alice@example.com',
          'gender': 'female',
          'created_at': fixedDateIso,
        },
        'related_user': {
          'id': 'user-2',
          'name': 'Bob',
          'email': 'bob@example.com',
          'gender': 'male',
          'created_at': fixedDateIso,
        },
      };

      final relation = UserRelation.fromMapWithRelated(map);

      expect(relation.user.id, 'user-1');
      expect(relation.user.name, 'Alice');
      expect(relation.relatedUser.id, 'user-2');
      expect(relation.relatedUser.name, 'Bob');
    });

    test('fromMapWithRelated handles flat structure (ids only)', () {
      final map = {'user_id': 'user-1', 'related_user_id': 'user-2'};

      final relation = UserRelation.fromMapWithRelated(map);

      expect(relation.user.id, 'user-1');
      expect(relation.relatedUser.id, 'user-2');
      expect(relation.user.name, '');
    });

    test('fromMapWithRelated prioritizes nested objects over flat ids', () {
      final map = {
        'user': {
          'id': 'user-1',
          'name': 'Alice',
          'email': 'alice@example.com',
          'gender': 'female',
          'created_at': fixedDateIso,
        },
        'user_id': 'user-999',
        'related_user': {
          'id': 'user-2',
          'name': 'Bob',
          'email': 'bob@example.com',
          'gender': 'male',
          'created_at': fixedDateIso,
        },
        'related_user_id': 'user-888',
      };

      final relation = UserRelation.fromMapWithRelated(map);

      expect(relation.user.id, 'user-1');
      expect(relation.relatedUser.id, 'user-2');
    });
  });
}
