import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:echo_lingua/core/errors/exceptions.dart';
import '../../domain/services/stt_service.dart';

class SpeechToTextService implements SttService {
  final stt.SpeechToText speechToText;
  final StreamController<double> _soundLevelController = StreamController<double>.broadcast();
  final StreamController<bool> _isListeningController = StreamController<bool>.broadcast();
  StreamController<String>? _textStreamController;

  SpeechToTextService({stt.SpeechToText? sttInstance})
      : speechToText = sttInstance ?? stt.SpeechToText();

  @override
  Future<bool> initialize() async {
    final available = await speechToText.initialize(
      onError: (val) {
        _isListeningController.add(false);
      },
      onStatus: (val) {
        _isListeningController.add(val == 'listening');
      },
    );
    return available;
  }

  @override
  Stream<String> startListening({required String locale}) {
    _textStreamController?.close();
    _textStreamController = StreamController<String>.broadcast();

    speechToText.listen(
      onResult: (result) {
        if (!_textStreamController!.isClosed) {
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
    ).catchError((err) {
      throw AudioException(message: 'Failed to start microphone: $err');
    });

    _isListeningController.add(true);
    return _textStreamController!.stream;
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
