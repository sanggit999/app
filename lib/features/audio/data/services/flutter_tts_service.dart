import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/services/tts_service.dart';

class FlutterTtsService implements TtsService {
  final FlutterTts flutterTts;
  final StreamController<bool> _isPlayingController = StreamController<bool>.broadcast();

  FlutterTtsService({FlutterTts? tts}) : flutterTts = tts ?? FlutterTts() {
    _initHandlers();
  }

  void _initHandlers() {
    flutterTts.setStartHandler(() {
      _isPlayingController.add(true);
    });

    flutterTts.setCompletionHandler(() {
      _isPlayingController.add(false);
    });

    flutterTts.setCancelHandler(() {
      _isPlayingController.add(false);
    });

    flutterTts.setErrorHandler((_) {
      _isPlayingController.add(false);
    });
  }

  @override
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  @override
  Future<void> speak({
    required String text,
    required String locale,
    double rate = 0.5,
    double pitch = 1.0,
  }) async {
    await flutterTts.stop();
    await flutterTts.setLanguage(locale);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await flutterTts.stop();
    _isPlayingController.add(false);
  }

  void dispose() {
    _isPlayingController.close();
  }
}
