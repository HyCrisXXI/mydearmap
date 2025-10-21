// lib/core/errors/memory_errors.dart
import 'package:supabase_flutter/supabase_flutter.dart';


class MemoryException implements Exception {
  final String message;
  final String code;

  MemoryException(this.message, {this.code = 'unknown'});

  @override
  String toString() => message;

  /// Memory no encontrada
  factory MemoryException.notFound(String title) {
    return MemoryException(
      "No se encontró ninguna memory con el título '$title'.",
      code: 'memory_not_found',
    );
  }

  /// Título duplicado
  factory MemoryException.duplicateTitle(String title) {
    return MemoryException(
      "Ya existe una memory con el título '$title'.",
      code: 'duplicate_title',
    );
  }

  /// Error de conexión
  factory MemoryException.networkError() {
    return MemoryException(
      "Error de conexión. Por favor verifica tu internet.",
      code: 'network_error',
    );
  }

  /// Error inesperado
  factory MemoryException.unknown([String? details]) {
    return MemoryException(
      "Ocurrió un error inesperado${details != null ? ': $details' : ''}",
      code: 'unknown',
    );
  }

  /// Conversión desde error de Supabase (PostgrestException)
  factory MemoryException.fromSupabase(PostgrestException e) {
    if (e.message.contains('duplicate')) {
      return MemoryException.duplicateTitle(''); // título opcional
    }
    if (e.message.contains('network')) {
      return MemoryException.networkError();
    }
    return MemoryException.unknown(e.message);
  }
}
