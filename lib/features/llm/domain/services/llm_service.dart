abstract class LlmService {
  /// Stream token chunks from local LLM for conversational latency
  Stream<String> streamChat({
    required List<Map<String, String>> messages,
    String? model,
    Map<String, dynamic>? options,
  });

  /// Single shot response for translation or structured analysis
  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    String? model,
  });

  /// Check if local LLM service (Ollama / local server) is running
  Future<bool> checkHealth();
}
