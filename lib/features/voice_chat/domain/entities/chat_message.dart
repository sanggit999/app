import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;
  final bool isPlayingAudio;
  final String? pronunciationNotes;
  final String? translatedText;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
    this.isPlayingAudio = false,
    this.pronunciationNotes,
    this.translatedText,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    bool? isPlayingAudio,
    String? pronunciationNotes,
    String? translatedText,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      isPlayingAudio: isPlayingAudio ?? this.isPlayingAudio,
      pronunciationNotes: pronunciationNotes ?? this.pronunciationNotes,
      translatedText: translatedText ?? this.translatedText,
    );
  }

  @override
  List<Object?> get props => [
    id,
    content,
    isUser,
    timestamp,
    isStreaming,
    isPlayingAudio,
    pronunciationNotes,
    translatedText,
  ];
}
