abstract class AudioRepository {
  Future<void> speak(String text, {required String locale, double rate = 0.5});
  Future<void> stopSpeaking();
  Stream<String> startListening({required String locale});
  Future<void> stopListening();
  Stream<double> get soundLevelStream;
  Stream<bool> get isListeningStream;
  Stream<bool> get isSpeakingStream;
}
