// lib/core/providers/memories_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/repositories/memory_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository(Supabase.instance.client);
});

final userMemoriesCacheProvider =
    NotifierProvider<UserMemoriesCacheNotifier, List<Memory>>(
      UserMemoriesCacheNotifier.new,
    );

class UserMemoriesCacheNotifier extends Notifier<List<Memory>> {
  @override
  List<Memory> build() {
    ref.listen(currentUserProvider, (previous, next) {
      final prevId = previous?.asData?.value?.id;
      final nextId = next.asData?.value?.id;
      if (prevId != nextId) {
        reset();
      }
    });
    return const <Memory>[];
  }

  void reset() => state = const <Memory>[];

  void setAll(List<Memory> items) {
    final copy = List<Memory>.of(items)
      ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    state = List<Memory>.unmodifiable(copy);
  }

  void upsert(Memory memory) {
    final updated = List<Memory>.of(state);
    final index = updated.indexWhere((element) => element.id == memory.id);
    if (index == -1) {
      updated.add(memory);
    } else {
      updated[index] = memory;
    }
    updated.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    state = List<Memory>.unmodifiable(updated);
  }

  void removeById(String? id) {
    if (id == null) return;
    state = List<Memory>.unmodifiable(
      state.where((memory) => memory.id != id).toList(),
    );
  }
}

final userMemoriesProvider = FutureProvider<List<Memory>>((ref) async {
  final userValue = ref.watch(currentUserProvider);
  final cacheNotifier = ref.read(userMemoriesCacheProvider.notifier);
  final cached = ref.read(userMemoriesCacheProvider);

  if (userValue.isLoading) {
    return cached;
  }

  if (userValue.hasError) {
    cacheNotifier.reset();
    throw userValue.error ?? Exception('No se pudo obtener el usuario actual');
  }

  final user = userValue.value;
  if (user == null) {
    cacheNotifier.reset();
    return const <Memory>[];
  }

  final memoryRepository = ref.read(memoryRepositoryProvider);
  try {
    final fetched = await memoryRepository.getMemoriesByUser(user.id);
    cacheNotifier.setAll(fetched);
    return fetched;
  } catch (error, stack) {
    cacheNotifier.reset();
    Error.throwWithStackTrace(error, stack);
  }
});
