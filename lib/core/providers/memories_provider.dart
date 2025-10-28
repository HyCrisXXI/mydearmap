// lib/core/providers/memories_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/repositories/memory_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository(Supabase.instance.client);
});

final mapMemoriesProvider = FutureProvider<List<MapMemory>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) {
        return [];
      }

      final memoryRepository = ref.read(memoryRepositoryProvider);
      return memoryRepository.getMemoriesForMap(user.id);
    },
    loading: () {
      return []; // Mientras el usuario carga, no mostramos recuerdos
    },
    error: (e, s) {
      return []; // Si hay un error al cargar el usuario, no mostramos recuerdos
    },
  );
});
