import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/services/tts_service.dart';

class FlutterTtsService implements TtsService {
  final FlutterTts flutterTts;
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();

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
    String voiceGender = 'female',
  }) async {
    await flutterTts.stop();
    await flutterTts.setLanguage(locale);
    await flutterTts.setSpeechRate(rate);

    final bool isMale = voiceGender.toLowerCase() == 'male';
    final double adjustedPitch = isMale ? 0.85 : 1.15;
    await flutterTts.setPitch(pitch == 1.0 ? adjustedPitch : pitch);

    try {
      final voices = await flutterTts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        final langPrefix = locale.split(RegExp(r'[-_]')).first.toLowerCase();
        final targetKeyword = isMale ? 'male' : 'female';

        Map<String, String>? selectedVoice;
        for (final v in voices) {
          if (v is Map) {
            final vLocale = (v['locale'] ?? '').toString().toLowerCase();
            final vName = (v['name'] ?? '').toString().toLowerCase();
            if (vLocale.contains(langPrefix) && vName.contains(targetKeyword)) {
              selectedVoice = {
                'name': v['name'].toString(),
                'locale': v['locale']?.toString() ?? locale,
              };
              break;
            }
          }
        }

        if (selectedVoice != null) {
          await flutterTts.setVoice(selectedVoice);
        }
      }
    } catch (_) {
      // Graceful fallback to pitch modulation
    }

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
