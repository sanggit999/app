import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:echo_lingua/core/errors/exceptions.dart';

import '../../domain/services/stt_service.dart';

class SpeechToTextService implements SttService {
  final stt.SpeechToText speechToText;
  final StreamController<double> _soundLevelController =
      StreamController<double>.broadcast();
  final StreamController<bool> _isListeningController =
      StreamController<bool>.broadcast();
  StreamController<String>? _textStreamController;

  SpeechToTextService({stt.SpeechToText? sttInstance})
    : speechToText = sttInstance ?? stt.SpeechToText();

  bool _isInitialized = false;

  @override
  Future<bool> initialize() async {
    try {
      final available = await speechToText.initialize(
        onError: (val) {
          _isListeningController.add(false);
        },
        onStatus: (val) {
          _isListeningController.add(val == 'listening');
        },
      );
      _isInitialized = available;
      return available;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  @override
  Stream<String> startListening({required String locale}) {
    _textStreamController?.close();
    _textStreamController = StreamController<String>.broadcast();

    _safeListen(locale);

    return _textStreamController!.stream;
  }

  Future<void> _safeListen(String locale) async {
    try {
      if (!_isInitialized || !speechToText.isAvailable) {
        final ready = await initialize();
        if (!ready) {
          _isListeningController.add(false);
          _textStreamController?.addError(
            const AudioException(
              message: 'Microphone permission not granted or unavailable',
            ),
          );
          return;
        }
      }

      await speechToText.listen(
        onResult: (result) {
          if (_textStreamController != null &&
              !_textStreamController!.isClosed) {
            _textStreamController!.add(result.recognizedWords);
          }
        },
        onSoundLevelChange: (level) {
          _soundLevelController.add(level);
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: locale,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );

      _isListeningController.add(true);
    } catch (err) {
      _isListeningController.add(false);
      if (_textStreamController != null && !_textStreamController!.isClosed) {
        _textStreamController!.addError(
          AudioException(message: 'Failed to start microphone: $err'),
        );
      }
    }
  }

  @override
  Future<void> stopListening() async {
    await speechToText.stop();
    _isListeningController.add(false);
    _soundLevelController.add(0.0);
    await _textStreamController?.close();
    _textStreamController = null;
  }

  @override
  Stream<double> get soundLevelStream => _soundLevelController.stream;

  @override
  Stream<bool> get isListeningStream => _isListeningController.stream;

  void dispose() {
    _soundLevelController.close();
    _isListeningController.close();
    _textStreamController?.close();
  }
}
