import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

// Estado del controlador de chat
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({required this.messages, required this.isLoading, this.error});

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Proveedor del controlador de chat usando NotifierProvider
class AiChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return ChatState(messages: [], isLoading: false);
  }

  // Añadir un mensaje del usuario
  void addUserMessage(String content) {
    final message = ChatMessage(
      id: const Uuid().v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, message]);
    _simulateAiResponse(content);
  }

  // Simular respuesta de la IA
  Future<void> _simulateAiResponse(String userMessage) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Simular un retraso de red
      await Future.delayed(const Duration(seconds: 2));

      // Generar una respuesta simulada de la IA
      final aiResponse = _generateAiResponse(userMessage);

      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al obtener respuesta: $e',
        isLoading: false,
      );
    }
  }

  // Generar una respuesta simulada de la IA
  String _generateAiResponse(String userMessage) {
    // Respuesta genérica simulada
    return 'Esta es una respuesta simulada a tu pregunta: "$userMessage".\n\n'
        'Integra una API real (OpenAI, Gemini, Claude, etc.) en EnvConstants y actualiza '
        '_simulateAiResponse para obtener respuestas verdaderas.';
  }

  // Limpiar el chat
  void clearChat() {
    state = ChatState(messages: [], isLoading: false);
  }
}

// Provider del controlador de chat
final aiChatControllerProvider = NotifierProvider<AiChatNotifier, ChatState>(
  () {
    return AiChatNotifier();
  },
);
