import 'dart:async';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/services/stt_service.dart';
import '../../domain/services/tts_service.dart';

class AudioRepositoryImpl implements AudioRepository {
  final TtsService ttsService;
  final SttService sttService;

  AudioRepositoryImpl({
    required this.ttsService,
    required this.sttService,
  });

  @override
  Future<void> speak(String text, {required String locale, double rate = 0.5}) async {
    // When bot starts speaking, ensure microphone isn't capturing bot's audio
    await sttService.stopListening();
    await ttsService.speak(text: text, locale: locale, rate: rate);
  }

  @override
  Future<void> stopSpeaking() async {
    await ttsService.stop();
  }

  @override
  Stream<String> startListening({required String locale}) {
    // Crucial: Stop TTS immediately when user wants to speak to prevent feedback echo loop
    unawaited(ttsService.stop());
    return sttService.startListening(locale: locale);
  }

  @override
  Future<void> stopListening() async {
    await sttService.stopListening();
  }

  @override
  Stream<double> get soundLevelStream => sttService.soundLevelStream;

  @override
  Stream<bool> get isListeningStream => sttService.isListeningStream;

  @override
  Stream<bool> get isSpeakingStream => ttsService.isPlayingStream;
}
