import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_relations_provider.dart';
import 'package:mydearmap/data/repositories/relation_repository.dart';

final relationControllerProvider =
    AsyncNotifierProvider<RelationController, void>(() {
      return RelationController();
    });

class RelationController extends AsyncNotifier<void> {
  RelationRepository get _repository => ref.read(relationRepositoryProvider);

  @override
  Future<void> build() async {
    // no inicialización necesaria
  }

  /// Crea una relación: acepta identifier que puede ser email, número o id.
  Future<void> createRelation({
    required String currentUserId,
    required String relatedUserIdentifier, // email, phone o id
    required String relationType,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _repository.createRelation(
        currentUserId: currentUserId,
        relatedUserIdentifier: relatedUserIdentifier,
        relationType: relationType,
      );

      // invalidar cache de relaciones del usuario
      ref.invalidate(userRelationsProvider(currentUserId));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteRelation({
    required String currentUserId,
    required String relatedUserId,
    required String relationType,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteRelation(
        currentUserId: currentUserId,
        relatedUserId: relatedUserId,
        relationType: relationType,
      );

      ref.invalidate(userRelationsProvider(currentUserId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateRelationColor({
    required String currentUserId,
    required String relatedUserId,
    required String colorHex,
  }) async {
    state = const AsyncValue.loading();
    try {
      final normalized = _normalizeColorHex(colorHex);
      await _repository.updateRelationColor(
        currentUserId: currentUserId,
        relatedUserId: relatedUserId,
        colorHex: normalized,
      );

      ref.invalidate(userRelationsProvider(currentUserId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  String _normalizeColorHex(String input) {
    var value = input.trim().toUpperCase();
    if (!value.startsWith('#')) value = '#$value';
    if (value.length == 4) {
      final r = value[1];
      final g = value[2];
      final b = value[3];
      value = '#$r$r$g$g$b$b';
    }
    final match = RegExp(r'^#([0-9A-F]{6})$').firstMatch(value);
    if (match == null) throw Exception('Formato de color inválido');
    return value;
  }
}
