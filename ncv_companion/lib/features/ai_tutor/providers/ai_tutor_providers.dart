import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:ncv_companion/core/services/connectivity_service.dart';
import 'package:ncv_companion/core/services/local_storage.dart';
import 'package:ncv_companion/core/services/supabase_service.dart';
import 'package:ncv_companion/core/utils/errors.dart';
import 'package:ncv_companion/features/auth/providers/auth_providers.dart';
import 'package:ncv_companion/features/ai_tutor/data/ai_tutor_repository.dart';
import 'package:ncv_companion/features/ai_tutor/models/chat_message.dart';

part 'ai_tutor_providers.g.dart';

class AiTutorState {
  const AiTutorState({
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isSending;

  /// Shown as an inline banner. Cleared when the next message is sent.
  final String? error;
}

@Riverpod(keepAlive: true)
AiTutorRepository aiTutorRepository(Ref ref) {
  return AiTutorRepository(
    client: ref.watch(supabaseProvider),
    storage: ref.watch(localStorageProvider),
  );
}

/// Chat state. It survives tab switches so an in-flight reply is not lost.
@Riverpod(keepAlive: true)
class AiTutorChat extends _$AiTutorChat {
  @override
  AiTutorState build() {
    ref.watch(authStateProvider); // reload history on sign-in / sign-out
    return AiTutorState(messages: ref.watch(aiTutorRepositoryProvider).readHistory());
  }

  Future<void> send(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || state.isSending) return;

    final repo = ref.read(aiTutorRepositoryProvider);
    final profile = ref.read(profileProvider).value;

    // The user's message appears immediately, and the history is persisted before the network call.
    final history = [...state.messages, ChatMessage.user(prompt)];
    state = AiTutorState(messages: history, isSending: true);
    await repo.saveHistory(history);

    try {
      if (!await ref.read(connectivityGateProvider).isOnline) {
        throw const OfflineException(
          'The AI Tutor needs an internet connection. Your chat is saved.',
        );
      }

      final reply = await repo.ask(
        history: history,
        nqfLevel: profile?.nqfLevel ?? 2,
        stream: profile?.vocationalStream ?? '',
      );

      final updated = [...history, ChatMessage.assistant(reply.reply)];
      state = AiTutorState(messages: updated);
      await repo.saveHistory(updated);

      // Refresh the server-side counter so the quota display updates.
      ref.invalidate(profileProvider);
    } catch (error) {
      state = AiTutorState(
        messages: history,
        error: error is AiTutorException ? error.message : friendlyError(error),
      );
    }
  }

  Future<void> clearHistory() async {
    state = const AiTutorState();
    await ref.read(aiTutorRepositoryProvider).saveHistory(const []);
  }
}
