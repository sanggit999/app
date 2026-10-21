import '../entities/chat_message.dart';

abstract class VoiceChatRepository {
  Stream<String> streamAiResponse({
    required List<ChatMessage> history,
    required String systemPrompt,
    String? model,
  });

  Future<String> translateMessage(String text, String targetLang);
}
