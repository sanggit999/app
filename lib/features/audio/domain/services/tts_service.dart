abstract class TtsService {
  Future<void> speak({
    required String text,
    required String locale,
    double rate = 0.5,
    double pitch = 1.0,
    String voiceGender = 'female',
  });

  Future<void> stop();

  Stream<bool> get isPlayingStream;
}
