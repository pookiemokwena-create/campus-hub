import 'package:ncv_companion/core/utils/ids.dart';

enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.user(String text) => ChatMessage(
        id: newLocalId(),
        role: ChatRole.user,
        content: text,
        createdAt: DateTime.now().toUtc(),
      );

  factory ChatMessage.assistant(String text) => ChatMessage(
        id: newLocalId(),
        role: ChatRole.assistant,
        content: text,
        createdAt: DateTime.now().toUtc(),
      );

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: ChatRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => ChatRole.user,
        ),
        content: json['content'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      );

  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role == ChatRole.user;

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };
}
