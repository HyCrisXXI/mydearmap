// lib/features/memories/controllers/memory_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mydearmap/data/models/memory.dart';
import 'package:mydearmap/data/repositories/memory_repository.dart';
import 'package:mydearmap/core/errors/memory_errors.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';

/// Provider del controlador
final memoryControllerProvider = AsyncNotifierProvider<MemoryController, void>(
  () {
    return MemoryController(MemoryRepository(Supabase.instance.client));
  },
);

class MemoryController extends AsyncNotifier<void> {
  final MemoryRepository _repository;

  MemoryController(this._repository);

  @override
  Future<void> build() async {
    return;
  }

  /// Crear un nuevo recuerdo
  Future<void> createMemory(Memory memory, String userId) async {
    state = const AsyncValue.loading();
    try {
      final createdM = await _repository.createMemory(memory, userId);
      if (createdM == null) throw Exception('No se pudo crear el recuerdo');
      ref.read(mapMemoriesCacheProvider.notifier).reset();
      ref.invalidate(mapMemoriesProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Obtener recuerdo por ID
  Future<Memory?> getMemoryById(String id) async {
    try {
      final memory = await _repository.getMemoryById(id);
      return memory;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener todos las recuerdo de un usuario
  Future<List<Memory>> getMemoriesByUser(String userId) async {
    try {
      final memories = await _repository.getMemoriesByUser(userId);
      return memories;
    } catch (e) {
      rethrow;
    }
  }

  /// Verificar si ya existe un recuerdo con el mismo título
  Future<bool> existsByTitle(String title) async {
    try {
      final exists = await _repository.existsByTitle(title);

      if (!exists) throw MemoryException.notFound(title);

      return exists;
    } catch (e) {
      rethrow;
    }
  }

  /// Eliminar un recuerdo por ID
  Future<void> deleteMemory(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteMemory(id);
      ref.read(mapMemoriesCacheProvider.notifier).reset();
      ref.invalidate(mapMemoriesProvider);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Actualizar un recuerdo existente
  Future<Memory?> updateMemory(Memory memory) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateMemory(memory);
      if (updated == null) throw Exception('No se pudo actualizar el recuerdo');
      ref.read(mapMemoriesCacheProvider.notifier).reset();
      ref.invalidate(mapMemoriesProvider);
      state = const AsyncValue.data(null);
      return updated;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
