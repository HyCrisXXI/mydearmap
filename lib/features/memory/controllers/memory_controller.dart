// lib/features/memory/controllers/memory_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/memory.dart';
import '../../../data/repositories/memory_repository.dart';
import '../../../core/errors/memory_errors.dart';

/// Provider del controlador
final memoryControllerProvider =
    AsyncNotifierProvider<MemoryController, void>(() {
  return MemoryController(MemoryRepository(Supabase.instance.client));
});

class MemoryController extends AsyncNotifier<void> {
  final MemoryRepository _repository;

  MemoryController(this._repository);

  @override
  Future<void> build() async {
    return;
  }

  /// Crear un nuevo recuerdo
  Future<void> createMemory(Memory memory) async {
    state = const AsyncValue.loading();
    try {
      final created = await _repository.createMemory(memory);
      if (created == null) throw Exception('No se pudo crear la memory');
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Obtener recuerdo por ID
  Future<Memory?> getMemoryById(String id) async {
    state = const AsyncValue.loading();
    try {
      final memory = await _repository.getMemoryById(id);
      state = const AsyncValue.data(null);
      return memory;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Obtener todos las recuerdo de un usuario
  Future<List<Memory>> getMemoriesByUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final memories = await _repository.getMemoriesByUser(userId);
      state = const AsyncValue.data(null);
      return memories;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Verificar si ya existe un recuerdo con el mismo título
  Future<bool> existsByTitle(String title) async {
  state = const AsyncValue.loading();
  try {
    final exists = await _repository.existsByTitle(title);

    if (!exists) throw MemoryException.notFound(title);

    state = const AsyncValue.data(null);
    return exists;
  } catch (e) {
    state = AsyncValue.error(e, StackTrace.current);
    rethrow;
  }
}


  /// Eliminar un recuerdo por ID
  Future<void> deleteMemory(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteMemory(id);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
