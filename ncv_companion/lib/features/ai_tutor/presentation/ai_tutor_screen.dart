import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ncv_companion/core/config/app_constants.dart';
import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/theme/app_theme.dart';
import 'package:ncv_companion/core/widgets/status_views.dart';
import 'package:ncv_companion/features/auth/providers/auth_providers.dart';
import 'package:ncv_companion/features/ai_tutor/models/chat_message.dart';
import 'package:ncv_companion/features/ai_tutor/presentation/widgets/message_bubble.dart';
import 'package:ncv_companion/features/ai_tutor/presentation/widgets/quick_prompt_chips.dart';
import 'package:ncv_companion/features/ai_tutor/providers/ai_tutor_providers.dart';

/// AI Tutor chat. Replies come from a server-side proxy, so the API key is never
/// on the device. The daily quota is enforced on the server.
class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _prefill(String template) {
    _input.value = TextEditingValue(
      text: template,
      selection: TextSelection.collapsed(offset: template.length),
    );
    _focus.requestFocus();
  }

  Future<void> _send() async {
    final text = _input.text;
    _input.clear();
    await ref.read(aiTutorChatProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(aiTutorChatProvider);
    final profile = ref.watch(profileProvider).value;
    final online = ref.watch(isOnlineProvider);
    final remaining =
        profile?.remainingAiQueries(DateTime.now().toUtc()) ?? AppConstants.aiDailyQueryLimit;
    final canSend = online && remaining > 0 && !chat.isSending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.bolt, size: 18),
              label: Text('$remaining/${AppConstants.aiDailyQueryLimit} left today'),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'clear') {
                ref.read(aiTutorChatProvider.notifier).clearHistory();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear chat on this device')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          QuickPromptChips(onSelected: _prefill),
          if (!online)
            const _Notice(
              icon: Icons.wifi_off,
              text: 'Offline. You can read past chats, but new questions need internet.',
            ),
          if (online && remaining == 0)
            const _Notice(
              icon: Icons.hourglass_bottom,
              text: 'Daily limit reached. It resets at midnight (SAST).',
            ),
          if (chat.error != null)
            _Notice(
              icon: Icons.error_outline,
              text: chat.error!,
              color: AppTheme.danger,
            ),
          Expanded(
            child: chat.messages.isEmpty && !chat.isSending
                ? const EmptyState(
                    icon: Icons.smart_toy_outlined,
                    title: 'Ask your AI tutor',
                    message:
                        'Ask about a concept, paste a lesson summary, or request practice questions for your NCV subject.',
                  )
                : _MessageList(messages: chat.messages, isSending: chat.isSending),
          ),
          _Composer(
            controller: _input,
            focusNode: _focus,
            enabled: canSend,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.isSending});

  final List<ChatMessage> messages;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final offset = isSending ? 1 : 0;
    // reverse: true keeps the newest message at the bottom without manual scrolling.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: messages.length + offset,
      itemBuilder: (context, index) {
        if (isSending && index == 0) return const _TypingIndicator();
        final message = messages[messages.length - 1 - (index - offset)];
        return MessageBubble(message: message);
      },
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text('Tutor is thinking…', style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: enabled ? (_) => onSend() : null,
                decoration: InputDecoration(
                  hintText: enabled ? 'Ask your tutor…' : 'Tutor unavailable right now',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = color ?? scheme.onTertiaryContainer;
    final background = color == null
        ? scheme.tertiaryContainer
        : color!.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: foreground))),
        ],
      ),
    );
  }
}
