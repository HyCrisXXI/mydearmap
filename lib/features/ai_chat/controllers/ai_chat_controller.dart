import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/providers/memories_provider.dart';
import 'package:mydearmap/data/models/memory.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../services/gemini_chat_service.dart';

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

class AiChatNotifier extends Notifier<ChatState> {
  static const List<String> _coordinateKeywords = <String>[
    'coordenada',
    'coordenadas',
    'latitud',
    'longitud',
    'ubicación exacta',
    'ubicacion exacta',
    'ubicación precisa',
    'ubicacion precisa',
    'gps',
  ];
  static const List<String> _fallbackPrompts = <String>[
    'Cafetería acogedora',
    'Mirador urbano',
    'Playa cercana',
    'Bosque tranquilo',
    'Mercado local',
    'Ruta ciclista',
    'Bar de tapas',
    'Pueblo mágico',
  ];
  late final GeminiChatService _chatService;
  DateFormat? _dateFormat;
  bool _localeReady = false;
  final Random _random = Random();

  @override
  ChatState build() {
    _chatService = ref.read(geminiChatServiceProvider);
    return ChatState(messages: [], isLoading: false);
  }

  Future<void> addUserMessage(String content) async {
    if (state.isLoading) return;

    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final message = ChatMessage(
      id: const Uuid().v4(),
      content: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, message], error: null);
    await _fetchAiResponse();
  }

  Future<void> _fetchAiResponse() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final includeCoordinates = _userRequestedCoordinates(state.messages);
      final memoryContext = await _buildMemoryContext(includeCoordinates);
      final aiResponse = await _chatService.sendMessage(
        history: state.messages,
        memoryContext: memoryContext,
      );

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
    } on GeminiChatException catch (error) {
      state = state.copyWith(error: error.message, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        error: 'Error al obtener respuesta de la IA. Intenta de nuevo.',
        isLoading: false,
      );
    }
  }

  Future<List<String>> generateSuggestedPrompts({int count = 4}) async {
    final prompts = <String>{};
    while (prompts.length < count) {
      final fallback =
          _fallbackPrompts[_random.nextInt(_fallbackPrompts.length)];
      prompts.add(fallback);
    }

    final result = prompts.toList()..shuffle(_random);
    return result.take(count).toList();
  }

  Future<String?> _buildMemoryContext(bool includeCoordinates) async {
    try {
      await _ensureLocaleInitialized();
      final memories = await _loadUserMemories();
      if (memories.isEmpty) return null;
      final summary = _summarizeMemories(memories, includeCoordinates);
      return summary.isEmpty ? null : summary;
    } catch (error, stack) {
      debugPrint('Error building memory context: $error\n$stack');
      return null;
    }
  }

  Future<void> _ensureLocaleInitialized() async {
    if (_localeReady) return;
    try {
      await initializeDateFormatting('es_ES');
      _localeReady = true;
    } catch (error, stack) {
      debugPrint(
        'No se pudo inicializar la localización es_ES: $error\n$stack',
      );
      _localeReady = true; // evitar llamadas repetidas
    }
  }

  Future<List<Memory>> _loadUserMemories() async {
    final cached = ref.read(userMemoriesCacheProvider);
    if (cached.isNotEmpty) {
      return cached;
    }

    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) {
      return const [];
    }

    final repository = ref.read(memoryRepositoryProvider);
    final memories = await repository.getMemoriesByUser(currentUser.id);
    ref.read(userMemoriesCacheProvider.notifier).setAll(memories);
    return memories;
  }

  String _summarizeMemories(List<Memory> memories, bool includeCoordinates) {
    if (memories.isEmpty) return '';
    final sorted = List<Memory>.of(memories)
      ..sort((a, b) => b.happenedAt.compareTo(a.happenedAt));

    final buffer = StringBuffer('Recuerdos recientes del usuario:\n');
    for (final memory in sorted.take(8)) {
      buffer.writeln(
        _formatMemoryLine(memory, includeCoordinates: includeCoordinates),
      );
    }
    return buffer.toString().trim();
  }

  String _formatMemoryLine(Memory memory, {required bool includeCoordinates}) {
    final dateLabel = _memoryDateFormat.format(memory.happenedAt);
    final location = memory.location;
    final locationLabel = location != null
        ? includeCoordinates
              ? ' en (${location.latitude.toStringAsFixed(2)}, '
                    '${location.longitude.toStringAsFixed(2)})'
              : ' en una ubicación guardada'
        : '';
    final peopleLabel = _formatParticipantsSummary(memory);
    final description = memory.description?.trim();
    final descLabel = (description == null || description.isEmpty)
        ? ''
        : ' — ${_truncate(description, 160)}';

    return '- $dateLabel • ${memory.title}$locationLabel$peopleLabel$descLabel';
  }

  bool _userRequestedCoordinates(List<ChatMessage> messages) {
    for (final message in messages.reversed) {
      if (!message.isUser) continue;
      final normalized = message.content.toLowerCase();
      for (final keyword in _coordinateKeywords) {
        if (normalized.contains(keyword)) {
          return true;
        }
      }
      break;
    }
    return false;
  }

  String _formatParticipantsSummary(Memory memory) {
    if (memory.participants.isEmpty) return '';

    final visible = memory.participants
        .take(3)
        .map(_formatParticipantLabel)
        .toList();
    final remaining = memory.participants.length - visible.length;
    final moreLabel = remaining > 0 ? ' y $remaining más' : '';
    return ' con ${visible.join(', ')}$moreLabel';
  }

  String _formatParticipantLabel(UserRole participant) {
    final name = participant.user.name.trim().isEmpty
        ? 'Invitado'
        : participant.user.name.trim();
    final roleLabel = _roleDisplayName(participant.role);
    return roleLabel == null ? name : '$name ($roleLabel)';
  }

  String? _roleDisplayName(MemoryRole role) {
    switch (role) {
      case MemoryRole.creator:
        return 'creador';
      case MemoryRole.participant:
        return 'participante';
      case MemoryRole.guest:
        return 'invitado';
    }
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 3)}...';
  }

  DateFormat get _memoryDateFormat {
    if (_dateFormat != null) {
      return _dateFormat!;
    }
    try {
      _dateFormat = DateFormat('d MMM yyyy', 'es_ES');
    } catch (error, stack) {
      debugPrint(
        'Fallo al crear el DateFormat es_ES, usando locale por defecto: '
        '$error\n$stack',
      );
      _dateFormat = DateFormat('d MMM yyyy');
    }
    return _dateFormat!;
  }

  // Limpiar el chat
  void clearChat() {
    state = ChatState(messages: [], isLoading: false);
  }

  void dismissError() {
    state = state.copyWith(error: null);
  }
}

// Provider del controlador de chat
final aiChatControllerProvider = NotifierProvider<AiChatNotifier, ChatState>(
  () {
    return AiChatNotifier();
  },
);

final chatSuggestionsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final notifier = ref.watch(aiChatControllerProvider.notifier);
  return notifier.generateSuggestedPrompts();
});
