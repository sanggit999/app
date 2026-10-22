import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:echo_lingua/core/errors/exceptions.dart';
import 'package:echo_lingua/features/llm/domain/services/llm_service.dart';

class OllamaLlmService implements LlmService {
  final http.Client client;
  final String baseUrl;
  final String defaultModel;

  OllamaLlmService({
    required this.client,
    this.baseUrl = 'http://127.0.0.1:11434',
    this.defaultModel = 'qwen2.5:3b',
  });

  @override
  Stream<String> streamChat({
    required List<Map<String, String>> messages,
    String? model,
    Map<String, dynamic>? options,
  }) async* {
    final uri = Uri.parse('$baseUrl/api/chat');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': model ?? defaultModel,
        'messages': messages,
        'stream': true,
        ...options != null ? {'options': options} : {},
      });

    http.StreamedResponse response;
    try {
      response = await client.send(request);
    } catch (e) {
      throw ServerException(
        message:
            'Cannot connect to Local LLM at $baseUrl. Ensure Ollama is running.',
      );
    }

    if (response.statusCode != 200) {
      throw ServerException(
        message: 'Ollama responded with error code: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      try {
        final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
        final message = decoded['message'] as Map<String, dynamic>?;
        if (message != null && message.containsKey('content')) {
          final content = message['content'] as String;
          if (content.isNotEmpty) {
            yield content;
          }
        }
      } catch (_) {
        // Skip malformed chunk line
      }
    }
  }

  @override
  Future<String> generate({
    required String prompt,
    String? systemPrompt,
    String? model,
  }) async {
    final uri = Uri.parse('$baseUrl/api/generate');
    try {
      final response = await client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model ?? defaultModel,
          'prompt': prompt,
          ...systemPrompt != null ? {'system': systemPrompt} : {},
          'stream': false,
        }),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Local LLM generation failed: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return decoded['response'] as String? ?? '';
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Cannot connect to Local LLM at $baseUrl: $e',
      );
    }
  }

  @override
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/api/tags');
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
