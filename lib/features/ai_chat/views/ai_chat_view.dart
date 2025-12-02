import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import 'package:mydearmap/core/widgets/app_nav_bar.dart';
import '../controllers/ai_chat_controller.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class AiChatView extends ConsumerStatefulWidget {
  const AiChatView({super.key});

  @override
  ConsumerState<AiChatView> createState() => _AiChatViewState();
}

enum _ChatMenuAction { clearChat }

class _AiChatViewState extends ConsumerState<AiChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(String text, AiChatNotifier chatNotifier) {
    final message = text.trim();
    if (message.isEmpty) return;

    chatNotifier.addUserMessage(message);
    _messageController.clear();
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatControllerProvider);
    final chatNotifier = ref.read(aiChatControllerProvider.notifier);
    final suggestionsAsync = ref.watch(chatSuggestionsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final userName = currentUserAsync.maybeWhen(
      data: (user) {
        final name = (user?.name ?? '').trim();
        if (name.isEmpty) {
          return '';
        }
        return name.split(' ').first;
      },
      orElse: () => '',
    );

    // Scroll automático cuando hay nuevos mensajes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: SweepGradient(
            center: Alignment.topRight,
            colors: [
              Color.fromARGB(255, 85, 111, 168),
              Color.fromARGB(255, 233, 226, 138),
              Color.fromARGB(255, 96, 145, 90),
            ],
            stops: [0.05, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
                child: Row(
                  children: [
                    PopupMenuButton<_ChatMenuAction>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == _ChatMenuAction.clearChat) {
                          chatNotifier.clearChat();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<_ChatMenuAction>(
                          value: _ChatMenuAction.clearChat,
                          enabled: chatState.messages.isNotEmpty,
                          child: Row(
                            children: const [
                              Icon(Icons.delete_outline),
                              SizedBox(width: 8),
                              Text('Borrar chat'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mapi',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tu asistente de aventuras',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de mensajes
              Expanded(
                child: chatState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: Colors.grey[700]),
                                children: [
                                  TextSpan(
                                    text:
                                        'Hola${userName.isNotEmpty ? ', $userName' : ''}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const TextSpan(text: '\n'),
                                  TextSpan(
                                    text: '¿Cuál es el plan de hoy?',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SuggestionChips(
                              prompts: suggestionsAsync,
                              disabled: chatState.isLoading,
                              onPromptTap: (prompt) =>
                                  _handleSendMessage(prompt, chatNotifier),
                              onRefresh: () =>
                                  ref.refresh(chatSuggestionsProvider),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatState.messages[index];
                          return _MessageBubble(message: message);
                        },
                      ),
              ),
              // Indicador de carga
              if (chatState.isLoading)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'La IA está pensando...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              // Mostrar errores
              if (chatState.error != null)
                Container(
                  color: Colors.red[100],
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chatState.error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              // Campo de entrada
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !chatState.isLoading,
                        decoration: InputDecoration(
                          hintText: 'Pregunta a Mapi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: Colors.grey[400]!,
                              width: 1,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          suffixIcon: _messageController.text.isEmpty
                              ? null
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                        onSubmitted: (value) {
                          if (!chatState.isLoading) {
                            _handleSendMessage(value, chatNotifier);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      mini: true,
                      onPressed:
                          chatState.isLoading || _messageController.text.isEmpty
                          ? null
                          : () => _handleSendMessage(
                              _messageController.text,
                              chatNotifier,
                            ),
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppNavBar(currentIndex: 0),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({
    required this.prompts,
    required this.disabled,
    required this.onPromptTap,
    required this.onRefresh,
  });

  final AsyncValue<List<String>> prompts;
  final bool disabled;
  final void Function(String prompt) onPromptTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return prompts.when(
      data: (items) {
        if (items.isEmpty) {
          return TextButton.icon(
            onPressed: disabled ? null : onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Generar ideas'),
          );
        }
        final primary = Theme.of(context).primaryColor;
        final chips = items.map((prompt) {
          final int borderAlphaLow = (255 * 0.3).round(); // 77
          final int borderAlphaHigh = (255 * 0.6).round(); // 153

          final int textAlphaLow = (255 * 0.5).round(); // 128
          final int textAlphaHigh = 255; // 1.0 = 255

          final borderColor = primary.withAlpha(
            disabled ? borderAlphaLow : borderAlphaHigh,
          );
          final textColor = Colors.black87.withAlpha(
            disabled ? textAlphaLow : textAlphaHigh,
          );

          final chipBody = Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Text(prompt, style: TextStyle(color: textColor)),
          );

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: disabled ? null : () => onPromptTap(prompt),
              child: chipBody,
            ),
          );
        }).toList();

        return Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: chips,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: disabled ? null : onRefresh,
              icon: const Icon(Icons.autorenew),
              label: const Text('Nuevas ideas'),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => Column(
        children: [
          Text(
            'No se pudieron cargar ideas.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton.icon(
            onPressed: disabled ? null : onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final dynamic message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser == true;
    const aiBorderColor = Color.fromARGB(255, 233, 226, 138);
    const userBaseColor = Color.fromARGB(255, 85, 111, 168);
    final bubbleColor = isUser ? userBaseColor : Colors.transparent;
    final borderColor = isUser
        ? userBaseColor
        : aiBorderColor.withValues(alpha: .6);
    final textColor = isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          border: isUser ? Border.all(color: borderColor, width: 1.2) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            isUser
                ? Text(message.content, style: TextStyle(color: textColor))
                : MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: textColor),
                      listBullet: TextStyle(color: textColor),
                      strong: TextStyle(color: textColor),
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: isUser ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
