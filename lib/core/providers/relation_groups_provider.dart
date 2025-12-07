import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/data/models/relation_group.dart';
import 'package:mydearmap/data/repositories/relation_group_repository.dart';

final userRelationGroupsProvider =
    FutureProvider.family<List<RelationGroup>, String>((ref, userId) async {
  final repository = ref.read(relationGroupRepositoryProvider);
  return repository.fetchGroups(userId);
});
