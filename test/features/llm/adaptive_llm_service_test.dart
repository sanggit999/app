import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_lingua/features/llm/data/services/adaptive_llm_service.dart';
import 'package:echo_lingua/features/llm/data/services/ollama_llm_service.dart';
import 'package:echo_lingua/features/llm/data/services/on_device_llm_service.dart';

class MockOllamaService extends Mock implements OllamaLlmService {}

class MockOnDeviceService extends Mock implements OnDeviceLlmService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockOllamaService mockOllama;
  late MockOnDeviceService mockOnDevice;
  late MockSharedPreferences mockPrefs;
  late AdaptiveLlmService adaptiveService;

  setUp(() {
    mockOllama = MockOllamaService();
    mockOnDevice = MockOnDeviceService();
    mockPrefs = MockSharedPreferences();

    adaptiveService = AdaptiveLlmService(
      ollamaService: mockOllama,
      onDeviceService: mockOnDevice,
      sharedPreferences: mockPrefs,
    );
  });

  test('delegates streamChat to Ollama when mode is ollama', () {
    when(() => mockPrefs.getString(AdaptiveLlmService.keyExecutionMode))
        .thenReturn('ollama');
    when(
      () => mockOllama.streamChat(
        messages: any(named: 'messages'),
        model: any(named: 'model'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) => Stream.value('Ollama reply'));

    final stream = adaptiveService.streamChat(
      messages: [
        {'role': 'user', 'content': 'hi'},
      ],
    );

    expect(stream, emits('Ollama reply'));
    verify(
      () => mockOllama.streamChat(
        messages: [
          {'role': 'user', 'content': 'hi'},
        ],
      ),
    ).called(1);
    verifyNever(
      () => mockOnDevice.streamChat(messages: any(named: 'messages')),
    );
  });

  test('delegates streamChat to OnDevice when mode is on_device', () {
    when(() => mockPrefs.getString(AdaptiveLlmService.keyExecutionMode))
        .thenReturn('on_device');
    when(
      () => mockOnDevice.streamChat(
        messages: any(named: 'messages'),
        model: any(named: 'model'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) => Stream.value('OnDevice reply'));

    final stream = adaptiveService.streamChat(
      messages: [
        {'role': 'user', 'content': 'hi'},
      ],
    );

    expect(stream, emits('OnDevice reply'));
    verify(
      () => mockOnDevice.streamChat(
        messages: [
          {'role': 'user', 'content': 'hi'},
        ],
      ),
    ).called(1);
    verifyNever(() => mockOllama.streamChat(messages: any(named: 'messages')));
  });

  test('delegates generate to active engine correctly', () async {
    when(() => mockPrefs.getString(AdaptiveLlmService.keyExecutionMode))
        .thenReturn('on_device');
    when(
      () => mockOnDevice.generate(
        prompt: any(named: 'prompt'),
        systemPrompt: any(named: 'systemPrompt'),
        model: any(named: 'model'),
      ),
    ).thenAnswer((_) async => 'Offline Generated text');

    final result = await adaptiveService.generate(prompt: 'Hello');

    expect(result, equals('Offline Generated text'));
    verify(() => mockOnDevice.generate(prompt: 'Hello')).called(1);
  });

  test('delegates checkHealth to active engine', () async {
    when(() => mockPrefs.getString(AdaptiveLlmService.keyExecutionMode))
        .thenReturn('ollama');
    when(() => mockOllama.checkHealth()).thenAnswer((_) async => true);

    final healthy = await adaptiveService.checkHealth();
    expect(healthy, isTrue);
    verify(() => mockOllama.checkHealth()).called(1);
  });
}
