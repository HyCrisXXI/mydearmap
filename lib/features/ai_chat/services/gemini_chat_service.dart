import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mydearmap/core/constants/env_constants.dart';
import 'package:mydearmap/features/ai_chat/models/chat_message.dart';

class GeminiChatException implements Exception {
  GeminiChatException(this.message);

  final String message;

  @override
  String toString() => 'GeminiChatException: $message';
}

class GeminiChatService {
  GeminiChatService({http.Client? client}) : _client = client ?? http.Client();

  static const String _model = 'models/gemini-2.5-flash-lite';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const double _temperature = 0.4;
  static const int _maxOutputTokens = 512;
  static const String _systemPrompt =
      'Eres el asistente de MyDearMap, tu nombre es Mapi. Responde siempre en español y ayuda '
      'a los usuarios con sus recuerdos, ubicaciones y eventos. No compartas coordenadas GPS '
      'ni datos de latitud/longitud a menos que el usuario lo solicite explícitamente; si no '
      'las pide, describe la ubicación de forma general.';

  final http.Client _client;

  /// Punto de entrada principal para enviar el historial del chat y obtener
  /// una respuesta generada por Gemini.
  Future<String> sendMessage({
    required List<ChatMessage> history,
    String? memoryContext,
  }) async {
    final apiKey = EnvConstants.geminiApiKey;
    if (apiKey.isEmpty) {
      throw GeminiChatException(
        'Falta la variable GEMINI_API_KEY en tu archivo .env.',
      );
    }

    if (history.isEmpty) {
      throw GeminiChatException('No se recibió ningún mensaje para procesar.');
    }

    final uri = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');

    final contents = <Map<String, dynamic>>[
      _buildSystemContent(),
      if (memoryContext != null && memoryContext.trim().isNotEmpty)
        _buildMemoryContextContent(memoryContext.trim()),
      ..._mapMessagesToContents(history),
    ];

    final payload = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': _temperature,
        'maxOutputTokens': _maxOutputTokens,
      },
    };

    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (error, stackTrace) {
      debugPrint('Gemini request failed: $error\n$stackTrace');
      throw GeminiChatException('No se pudo contactar con Gemini.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiChatException(_extractError(response.body));
    }

    return _extractText(response.body);
  }

  List<Map<String, dynamic>> _mapMessagesToContents(List<ChatMessage> history) {
    return history
        .map(
          (message) => {
            'role': message.isUser ? 'user' : 'model',
            'parts': [
              {'text': message.content},
            ],
          },
        )
        .toList();
  }

  Map<String, dynamic> _buildSystemContent() {
    return {
      'role': 'user',
      'parts': [
        {'text': _systemPrompt},
      ],
    };
  }

  Map<String, dynamic> _buildMemoryContextContent(String context) {
    return {
      'role': 'user',
      'parts': [
        {
          'text':
              'Contexto de recuerdos del usuario (mantén la privacidad y '
              'usa esta información solo cuando sea relevante):\n$context',
        },
      ],
    };
  }

  String _extractText(String rawBody) {
    final decoded = jsonDecode(rawBody) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      final promptFeedback = decoded['promptFeedback'];
      if (promptFeedback != null) {
        return 'La solicitud fue bloqueada: $promptFeedback';
      }
      throw GeminiChatException('Gemini no devolvió ninguna respuesta.');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final buffer = StringBuffer();

    if (parts != null && parts.isNotEmpty) {
      for (final part in parts) {
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) {
          buffer.writeln(text.trim());
        }
      }
    }

    final result = buffer.toString().trim();
    if (result.isEmpty) {
      return 'No pude generar una respuesta útil esta vez, ¿podrías intentar formularlo de otra manera?';
    }

    return result;
  }

  String _extractError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>?;
      final message = error?['message'];
      if (message is String && message.isNotEmpty) {
        return 'Gemini respondió con un error: $message';
      }
    } catch (_) {
      // Ignorar errores de parseo y devolver un mensaje genérico.
    }
    return 'Gemini respondió con un estado inesperado.';
  }

  void dispose() {
    _client.close();
  }
}

final geminiChatServiceProvider = Provider<GeminiChatService>((ref) {
  final service = GeminiChatService();
  ref.onDispose(service.dispose);
  return service;
});
