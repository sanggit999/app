import '../entities/chat_message.dart';
import '../repositories/voice_chat_repository.dart';

class SendMessageStreamUseCase {
  final VoiceChatRepository repository;

  SendMessageStreamUseCase(this.repository);

  Stream<String> call({
    required List<ChatMessage> history,
    required String systemPrompt,
    String? model,
  }) {
    return repository.streamAiResponse(
      history: history,
      systemPrompt: systemPrompt,
      model: model,
    );
  }
}
