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

    final bool isMale = voiceGender.toLowerCase() == 'male';

    try {
      final voices = await flutterTts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        final langPrefix = locale.split(RegExp(r'[-_]')).first.toLowerCase();

        Map<String, String>? selectedVoice;
        for (final v in voices) {
          if (v is Map) {
            final vLocale = (v['locale'] ?? '').toString().toLowerCase();
            final vName = (v['name'] ?? '').toString().toLowerCase();
            final vGender = (v['gender'] ?? '').toString().toLowerCase();

            if (vLocale.contains(langPrefix)) {
              if (isMale) {
                // Must explicitly match male and MUST NOT match female (since 'female'.contains('male') is true!)
                final isExplicitMale = vGender == 'male' ||
                    (vName.contains('male') && !vName.contains('female')) ||
                    vName.contains('david') ||
                    vName.contains('alex') ||
                    vName.contains('george') ||
                    vName.contains('daniel') ||
                    vName.contains('guy') ||
                    vName.contains('-b-') ||
                    vName.contains('-d-') ||
                    vName.contains('vic');
                if (isExplicitMale) {
                  selectedVoice = {
                    'name': v['name'].toString(),
                    'locale': v['locale']?.toString() ?? locale,
                  };
                  break;
                }
              } else {
                final isExplicitFemale = vGender == 'female' ||
                    vName.contains('female') ||
                    vName.contains('zira') ||
                    vName.contains('samantha') ||
                    vName.contains('karen') ||
                    vName.contains('victoria') ||
                    vName.contains('aria') ||
                    vName.contains('jenny') ||
                    vName.contains('-a-') ||
                    vName.contains('-c-') ||
                    vName.contains('vif');
                if (isExplicitFemale) {
                  selectedVoice = {
                    'name': v['name'].toString(),
                    'locale': v['locale']?.toString() ?? locale,
                  };
                  break;
                }
              }
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

    // Set pitch & speech rate AFTER setVoice so Android TTS engine doesn't reset them!
    // Distinct pitch: 0.72 for deep resonant male baritone, 1.20 for clear female tone
    final double adjustedPitch = isMale ? 0.72 : 1.20;
    final double finalPitch = pitch == 1.0 ? adjustedPitch : pitch;
    await flutterTts.setPitch(finalPitch);
    await flutterTts.setSpeechRate(rate);

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
