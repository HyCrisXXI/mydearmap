// lib/core/providers/memories_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/repositories/memory_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository(Supabase.instance.client);
});

final mapMemoriesCacheProvider =
    NotifierProvider<MapMemoriesCacheNotifier, List<MapMemory>>(
      MapMemoriesCacheNotifier.new,
    );

class MapMemoriesCacheNotifier extends Notifier<List<MapMemory>> {
  @override
  List<MapMemory> build() => const <MapMemory>[];

  void reset() => state = const <MapMemory>[];

  void setAll(List<MapMemory> items) =>
      state = List<MapMemory>.unmodifiable(items);
}

final mapMemoriesProvider = FutureProvider<List<MapMemory>>((ref) async {
  final userValue = ref.watch(currentUserProvider);

  if (userValue.isLoading) {
    return ref.read(mapMemoriesCacheProvider);
  }

  if (userValue.hasError) {
    ref.read(mapMemoriesCacheProvider.notifier).reset();
    return const <MapMemory>[];
  }

  final user = userValue.value;
  if (user == null) {
    ref.read(mapMemoriesCacheProvider.notifier).reset();
    return const <MapMemory>[];
  }

  final cached = ref.read(mapMemoriesCacheProvider);
  if (cached.isNotEmpty) return cached;

  final memoryRepository = ref.read(memoryRepositoryProvider);
  final fetched = await memoryRepository.getMemoriesForMap(user.id);
  ref.read(mapMemoriesCacheProvider.notifier).setAll(fetched);
  return fetched;
});
final memoriesProvider = FutureProvider.family<List<Memory>, String>((
  ref,
  userId,
) async {
  final memoryRepository = ref.read(memoryRepositoryProvider);

  // Ajusta el nombre del método si tu MemoryRepository usa otro (ej. getMemories, getAllForUser, etc.)
  // Aquí intento llamar a `getMemoriesForUser`. Si tu repo tiene distinto nombre cámbialo.
  final fetched = await memoryRepository.getMemoriesByUser(userId);

  // Asegura que devuelva una lista no nula
  return fetched;
});
