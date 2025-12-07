import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/memory.dart';

final groupMemoriesProvider = FutureProvider.family<List<Memory>, String>(
  (ref, groupId) async {
    final repository = ref.read(memoryRepositoryProvider);
    return repository.getMemoriesByGroup(groupId);
  },
);
