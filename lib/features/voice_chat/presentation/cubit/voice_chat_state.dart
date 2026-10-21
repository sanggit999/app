import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

class VoiceChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isListening;
  final double soundLevel;
  final String partialRecognizedText;
  final bool isThinking;
  final bool isStreaming;
  final String? speakingMessageId;
  final String? errorMessage;
  final bool autoPlayTts;

  const VoiceChatState({
    this.messages = const [],
    this.isListening = false,
    this.soundLevel = 0.0,
    this.partialRecognizedText = '',
    this.isThinking = false,
    this.isStreaming = false,
    this.speakingMessageId,
    this.errorMessage,
    this.autoPlayTts = true,
  });

  bool get isBusy => isThinking || isStreaming || isListening;

  VoiceChatState copyWith({
    List<ChatMessage>? messages,
    bool? isListening,
    double? soundLevel,
    String? partialRecognizedText,
    bool? isThinking,
    bool? isStreaming,
    String? speakingMessageId,
    bool clearSpeakingId = false,
    String? errorMessage,
    bool clearError = false,
    bool? autoPlayTts,
  }) {
    return VoiceChatState(
      messages: messages ?? this.messages,
      isListening: isListening ?? this.isListening,
      soundLevel: soundLevel ?? this.soundLevel,
      partialRecognizedText: partialRecognizedText ?? this.partialRecognizedText,
      isThinking: isThinking ?? this.isThinking,
      isStreaming: isStreaming ?? this.isStreaming,
      speakingMessageId: clearSpeakingId ? null : (speakingMessageId ?? this.speakingMessageId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      autoPlayTts: autoPlayTts ?? this.autoPlayTts,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isListening,
        soundLevel,
        partialRecognizedText,
        isThinking,
        isStreaming,
        speakingMessageId,
        errorMessage,
        autoPlayTts,
      ];
}
