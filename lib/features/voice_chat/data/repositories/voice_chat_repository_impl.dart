import 'package:echo_lingua/features/llm/domain/services/llm_service.dart';
import 'package:echo_lingua/features/voice_chat/domain/entities/chat_message.dart';
import 'package:echo_lingua/features/voice_chat/domain/repositories/voice_chat_repository.dart';

class VoiceChatRepositoryImpl implements VoiceChatRepository {
  final LlmService llmService;

  VoiceChatRepositoryImpl({required this.llmService});

  @override
  Stream<String> streamAiResponse({
    required List<ChatMessage> history,
    required String systemPrompt,
    String? model,
  }) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (final msg in history) {
      if (msg.content.trim().isNotEmpty) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    return llmService.streamChat(messages: messages, model: model);
  }

  @override
  Future<String> translateMessage(String text, String targetLang) async {
    return llmService.generate(
      prompt:
          'Translate the following sentence to $targetLang accurately and naturally: "$text". Output ONLY the translation.',
    );
  }
}
