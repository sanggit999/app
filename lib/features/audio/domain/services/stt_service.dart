abstract class SttService {
  Future<bool> initialize();

  Stream<String> startListening({required String locale});

  Future<void> stopListening();

  Stream<double> get soundLevelStream;

  Stream<bool> get isListeningStream;
}
