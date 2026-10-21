import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:echo_lingua/features/audio/domain/services/tts_service.dart';
import 'package:echo_lingua/features/audio/domain/services/stt_service.dart';
import 'package:echo_lingua/features/audio/data/repositories/audio_repository_impl.dart';

class MockTtsService extends Mock implements TtsService {}
class MockSttService extends Mock implements SttService {}

void main() {
  late MockTtsService mockTts;
  late MockSttService mockStt;
  late AudioRepositoryImpl repo;

  setUp(() {
    mockTts = MockTtsService();
    mockStt = MockSttService();
    repo = AudioRepositoryImpl(ttsService: mockTts, sttService: mockStt);
  });

  test('startListening stops TTS to prevent feedback loop and starts STT', () async {
    when(() => mockTts.stop()).thenAnswer((_) async {});
    when(() => mockStt.startListening(locale: any(named: 'locale')))
        .thenAnswer((_) => Stream.value('test spoken word'));

    final stream = repo.startListening(locale: 'en-US');
    final word = await stream.first;

    expect(word, equals('test spoken word'));
    verify(() => mockTts.stop()).called(1);
    verify(() => mockStt.startListening(locale: 'en-US')).called(1);
  });

  test('speak stops STT before speaking to avoid acoustic feedback', () async {
    when(() => mockStt.stopListening()).thenAnswer((_) async {});
    when(() => mockTts.speak(
          text: any(named: 'text'),
          locale: any(named: 'locale'),
          rate: any(named: 'rate'),
        )).thenAnswer((_) async {});

    await repo.speak('Hello world', locale: 'en-US');

    verify(() => mockStt.stopListening()).called(1);
    verify(() => mockTts.speak(text: 'Hello world', locale: 'en-US', rate: 0.5)).called(1);
  });
}
