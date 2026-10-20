import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ncv_companion/core/config/app_constants.dart';
import 'package:ncv_companion/core/services/local_storage.dart';
import 'package:ncv_companion/features/ai_tutor/models/chat_message.dart';

class AiTutorException implements Exception {
  const AiTutorException(this.message, {this.isQuotaExceeded = false});

  final String message;
  final bool isQuotaExceeded;

  @override
  String toString() => message;
}

class AiReply {
  const AiReply({required this.reply, required this.remaining});

  final String reply;
  final int remaining;
}

/// Calls the `ai-tutor` Supabase Edge Function. The LLM API key lives only on
/// the server. The app never holds it.
class AiTutorRepository {
  AiTutorRepository({
    required SupabaseClient client,
    required LocalStorage storage,
  })  : _client = client,
        _storage = storage;

  final SupabaseClient _client;
  final LocalStorage _storage;

  static const _historyPrefix = 'chat::';
  static const _maxStoredMessages = 60;

  String? get _uid => _client.auth.currentUser?.id;

  List<ChatMessage> readHistory() {
    final uid = _uid;
    if (uid == null) return const [];
    final rows = _storage.readList(_storage.chat, '$_historyPrefix$uid') ?? const [];
    return rows
        .map((row) => ChatMessage.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveHistory(List<ChatMessage> messages) {
    final uid = _uid;
    if (uid == null) return Future.value();
    final trimmed = messages.length > _maxStoredMessages
        ? messages.sublist(messages.length - _maxStoredMessages)
        : messages;
    return _storage.writeJson(
      _storage.chat,
      '$_historyPrefix$uid',
      trimmed.map((m) => m.toJson()).toList(),
    );
  }

  /// Sends only the most recent turns to bound cost and latency. The server
  /// re-validates everything, so this client-side trim is not a security control.
  Future<AiReply> ask({
    required List<ChatMessage> history,
    required int nqfLevel,
    required String stream,
  }) async {
    final recent = history.length > AppConstants.aiHistoryTurns
        ? history.sublist(history.length - AppConstants.aiHistoryTurns)
        : history;

    try {
      final response = await _client.functions.invoke(
        'ai-tutor',
        body: {
          'messages': [
            for (final message in recent)
              {'role': message.role.name, 'content': message.content},
          ],
          'nqf_level': nqfLevel,
          'vocational_stream': stream,
        },
      );

      final data = response.data;
      if (data is! Map) {
        throw const AiTutorException('The tutor sent an unexpected response.');
      }
      return AiReply(
        reply: data['reply'] as String? ?? '',
        remaining: (data['remaining'] as num?)?.toInt() ?? 0,
      );
    } on FunctionException catch (error) {
      if (error.status == 429) {
        throw const AiTutorException(
          "You've used today's AI queries. The limit resets at midnight (SAST).",
          isQuotaExceeded: true,
        );
      }
      throw AiTutorException(
        'The tutor is unavailable right now (code ${error.status}). Try again shortly.',
      );
    }
  }
}
