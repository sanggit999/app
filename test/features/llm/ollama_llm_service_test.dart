import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:echo_lingua/features/llm/data/services/ollama_llm_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

void main() {
  late MockHttpClient mockClient;
  late OllamaLlmService service;

  setUpAll(() {
    registerFallbackValue(FakeBaseRequest());
    registerFallbackValue(Uri.parse('http://127.0.0.1:11434'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = OllamaLlmService(
      client: mockClient,
      baseUrl: 'http://127.0.0.1:11434',
      defaultModel: 'qwen2.5:3b',
    );
  });

  test(
    'streamChat correctly decodes chunked streaming responses from Ollama',
    () async {
      final streamResponse = http.StreamedResponse(
        Stream.fromIterable([
          utf8.encode(
            '{"message":{"role":"assistant","content":"Xin"},"done":false}\n',
          ),
          utf8.encode(
            '{"message":{"role":"assistant","content":" chào"},"done":false}\n',
          ),
          utf8.encode(
            '{"message":{"role":"assistant","content":" bạn!"},"done":true}\n',
          ),
        ]),
        200,
      );

      when(() => mockClient.send(any()))
          .thenAnswer((_) async => streamResponse);

      final result = await service
          .streamChat(
            messages: [
              {'role': 'user', 'content': 'Chào'},
            ],
          )
          .toList();

      expect(result, equals(['Xin', ' chào', ' bạn!']));
    },
  );

  test('generate returns parsed response on 200 OK', () async {
    when(
      () => mockClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response('{"response": "Hello world"}', 200),
    );

    final result = await service.generate(prompt: 'Say hello');
    expect(result, equals('Hello world'));
  });

  test('checkHealth returns true when api/tags returns 200', () async {
    when(() => mockClient.get(any()))
        .thenAnswer((_) async => http.Response('{"models": []}', 200));

    final isHealthy = await service.checkHealth();
    expect(isHealthy, isTrue);
  });
}
