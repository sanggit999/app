import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:echo_lingua/features/audio/domain/repositories/audio_repository.dart';
import 'package:echo_lingua/features/voice_chat/domain/entities/chat_message.dart';
import 'package:echo_lingua/features/voice_chat/domain/repositories/voice_chat_repository.dart';
import 'package:echo_lingua/features/voice_chat/domain/usecases/send_message_stream_usecase.dart';
import 'voice_chat_state.dart';

class VoiceChatCubit extends Cubit<VoiceChatState> {
  final SendMessageStreamUseCase sendMessageStreamUseCase;
  final AudioRepository audioRepository;
  final VoiceChatRepository voiceChatRepository;

  StreamSubscription<String>? _sttTextSubscription;
  StreamSubscription<double>? _soundLevelSubscription;
  StreamSubscription<bool>? _speakingSubscription;
  StreamSubscription<String>? _llmStreamSubscription;

  VoiceChatCubit({
    required this.sendMessageStreamUseCase,
    required this.audioRepository,
    required this.voiceChatRepository,
  }) : super(const VoiceChatState()) {
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _speakingSubscription = audioRepository.isSpeakingStream.listen((isSpeaking) {
      if (!isSpeaking && state.speakingMessageId != null) {
        emit(state.copyWith(clearSpeakingId: true));
      }
    });
  }

  Future<void> startListening({required String locale}) async {
    await stopAudio();
    emit(state.copyWith(
      isListening: true,
      partialRecognizedText: '',
      soundLevel: 0.0,
      clearError: true,
    ));

    try {
      _soundLevelSubscription?.cancel();
      _soundLevelSubscription = audioRepository.soundLevelStream.listen((level) {
        emit(state.copyWith(soundLevel: level));
      });

      _sttTextSubscription?.cancel();
      final stream = audioRepository.startListening(locale: locale);
      _sttTextSubscription = stream.listen(
        (recognized) {
          emit(state.copyWith(partialRecognizedText: recognized));
        },
        onError: (err) {
          emit(state.copyWith(
            isListening: false,
            errorMessage: 'Microphone error: $err',
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isListening: false,
        errorMessage: 'Could not access microphone: $e',
      ));
    }
  }

  Future<void> stopListeningAndSend({
    required String systemPrompt,
    required String ttsLocale,
    String? model,
  }) async {
    await _sttTextSubscription?.cancel();
    await _soundLevelSubscription?.cancel();
    await audioRepository.stopListening();

    final text = state.partialRecognizedText.trim();
    emit(state.copyWith(
      isListening: false,
      soundLevel: 0.0,
      partialRecognizedText: '',
    ));

    if (text.isNotEmpty) {
      await sendMessage(
        content: text,
        systemPrompt: systemPrompt,
        ttsLocale: ttsLocale,
        model: model,
      );
    }
  }

  Future<void> cancelListening() async {
    await _sttTextSubscription?.cancel();
    await _soundLevelSubscription?.cancel();
    await audioRepository.stopListening();
    emit(state.copyWith(
      isListening: false,
      soundLevel: 0.0,
      partialRecognizedText: '',
    ));
  }

  Future<void> sendMessage({
    required String content,
    required String systemPrompt,
    required String ttsLocale,
    String? model,
  }) async {
    if (content.trim().isEmpty) return;

    await stopAudio();

    final userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    final assistantMsgId = '${DateTime.now().microsecondsSinceEpoch}_ai';
    final placeholderAssistant = ChatMessage(
      id: assistantMsgId,
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..add(userMessage)
      ..add(placeholderAssistant);

    emit(state.copyWith(
      messages: updatedMessages,
      isThinking: true,
      isStreaming: true,
      clearError: true,
    ));

    final StringBuffer accumulatedReply = StringBuffer();

    try {
      _llmStreamSubscription?.cancel();
      final stream = sendMessageStreamUseCase(
        history: updatedMessages.sublist(0, updatedMessages.length - 1),
        systemPrompt: systemPrompt,
        model: model,
      );

      _llmStreamSubscription = stream.listen(
        (chunk) {
          accumulatedReply.write(chunk);

          final currentMessages = List<ChatMessage>.from(state.messages);
          final index = currentMessages.indexWhere((m) => m.id == assistantMsgId);
          if (index != -1) {
            currentMessages[index] = currentMessages[index].copyWith(
              content: accumulatedReply.toString(),
              isStreaming: true,
            );
            emit(state.copyWith(
              messages: currentMessages,
              isThinking: false,
            ));
          }
        },
        onDone: () async {
          final currentMessages = List<ChatMessage>.from(state.messages);
          final index = currentMessages.indexWhere((m) => m.id == assistantMsgId);
          if (index != -1) {
            currentMessages[index] = currentMessages[index].copyWith(
              isStreaming: false,
            );
          }

          emit(state.copyWith(
            messages: currentMessages,
            isThinking: false,
            isStreaming: false,
          ));

          if (state.autoPlayTts && accumulatedReply.isNotEmpty) {
            await playMessageAudio(
              currentMessages[index],
              locale: ttsLocale,
            );
          }
        },
        onError: (err) {
          emit(state.copyWith(
            isThinking: false,
            isStreaming: false,
            errorMessage: 'Local LLM connection error: $err',
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isThinking: false,
        isStreaming: false,
        errorMessage: 'Failed to process message: $e',
      ));
    }
  }

  Future<void> playMessageAudio(ChatMessage message, {required String locale}) async {
    try {
      emit(state.copyWith(speakingMessageId: message.id));
      await audioRepository.speak(message.content, locale: locale);
    } catch (e) {
      emit(state.copyWith(
        clearSpeakingId: true,
        errorMessage: 'TTS playback error: $e',
      ));
    }
  }

  Future<void> stopAudio() async {
    await audioRepository.stopSpeaking();
    emit(state.copyWith(clearSpeakingId: true));
  }

  Future<void> translateMessage(String messageId, {required String targetLang}) async {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    try {
      final msg = state.messages[index];
      final translated = await voiceChatRepository.translateMessage(msg.content, targetLang);
      final currentList = List<ChatMessage>.from(state.messages);
      currentList[index] = msg.copyWith(translatedText: translated.trim());
      emit(state.copyWith(messages: currentList));
    } catch (_) {}
  }

  void toggleAutoPlayTts() {
    emit(state.copyWith(autoPlayTts: !state.autoPlayTts));
  }

  void clearChat() {
    stopAudio();
    _llmStreamSubscription?.cancel();
    emit(state.copyWith(
      messages: [],
      isThinking: false,
      isStreaming: false,
      isListening: false,
      clearSpeakingId: true,
      clearError: true,
    ));
  }

  @override
  Future<void> close() {
    _sttTextSubscription?.cancel();
    _soundLevelSubscription?.cancel();
    _speakingSubscription?.cancel();
    _llmStreamSubscription?.cancel();
    return super.close();
  }
}
