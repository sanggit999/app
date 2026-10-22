abstract class AudioRepository {
  Future<void> speak(
    String text, {
    required String locale,
    double rate = 0.5,
    double pitch = 1.0,
    String voiceGender = 'female',
  });
  Future<void> stopSpeaking();
  Stream<String> startListening({required String locale});
  Future<void> stopListening();
  Stream<double> get soundLevelStream;
  Stream<bool> get isListeningStream;
  Stream<bool> get isSpeakingStream;
}
