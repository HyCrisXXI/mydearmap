import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mydearmap/core/constants/constants.dart';
import 'package:mydearmap/core/providers/current_user_provider.dart';
import '../controllers/ai_chat_controller.dart';

class AiChatView extends ConsumerStatefulWidget {
  const AiChatView({super.key});

  @override
  ConsumerState<AiChatView> createState() => _AiChatViewState();
}

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

    final canSend =
        !chatState.isLoading && _messageController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppIcons.aiBG),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    AppSizes.upperPadding,
                    16,
                    20,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(AppIcons.trash),
                        onPressed: () => chatNotifier.clearChat(),
                        style: AppButtonStyles.circularIconButton,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 36),
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
                                    ?.copyWith(color: AppColors.textColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Lista de mensajes
                Expanded(
                  child: chatState.messages.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSizes.paddingMedium,
                                      AppSizes.paddingLarge * 4,
                                      AppSizes.paddingMedium,
                                      AppSizes.paddingMedium,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color: AppColors.textColor,
                                                ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    'Hola${userName.isNotEmpty ? ', $userName' : ''}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textColor,
                                                ),
                                              ),
                                              const TextSpan(text: '\n'),
                                              TextSpan(
                                                text:
                                                    '¿Cuál es el plan de hoy?',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _SuggestionChips(
                                          prompts: suggestionsAsync,
                                          disabled: chatState.isLoading,
                                          onPromptTap: (prompt) =>
                                              _handleSendMessage(
                                                prompt,
                                                chatNotifier,
                                              ),
                                          onRefresh: () => ref.refresh(
                                            chatSuggestionsProvider,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
                          'Estoy pensando...',
                          style: TextStyle(
                            color: AppColors.textGray,
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
                                color: AppColors.textGray,
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
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: canSend
                                    ? () => _handleSendMessage(
                                        _messageController.text,
                                        chatNotifier,
                                      )
                                    : null,
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.transparent,
                                  child: SvgPicture.asset(
                                    AppIcons.send,
                                    width: 18,
                                    height: 18,
                                    colorFilter: ColorFilter.mode(
                                      canSend
                                          ? AppColors.blue
                                          : AppColors.textColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minHeight: 44,
                              minWidth: 48,
                            ),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  final AsyncValue<List<ChatPrompt>> prompts;
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

        final chips = items.map((prompt) {
          final int textAlphaLow = (255 * 0.5).round(); // 128
          final int textAlphaHigh = 255; // 1.0 = 255

          final textColor = AppColors.textColor.withAlpha(
            disabled ? textAlphaLow : textAlphaHigh,
          );

          final chipBody = Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.buttonBackground),
            ),
            child: Text(prompt.label, style: TextStyle(color: textColor)),
          );

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: disabled ? null : () => onPromptTap(prompt.query),
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
    final bubbleColor = isUser ? AppColors.blue : Colors.transparent;
    final textColor = isUser ? Colors.white : Colors.black87;

    // User: Fixed Width 264. AI: Max Width 85%.
    final constraints = isUser
        ? const BoxConstraints(minWidth: 264, maxWidth: 264)
        : BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85);

    // User: Padding handled inside children (Stack). AI: Padding on container.
    final containerPadding = isUser
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 6);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: containerPadding,
        constraints: constraints,
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: isUser
              ? const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(2),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )
              : null,
        ),
        child: isUser
            ? Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 18,
                      bottom: 18,
                      left: 19,
                      right: 19,
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 12,
                    child: Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ),
                ],
              )
            : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: textColor),
                  listBullet: TextStyle(color: textColor),
                  strong: TextStyle(color: textColor),
                ),
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
