import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:echo_lingua/features/audio/domain/repositories/audio_repository.dart';
import 'package:echo_lingua/features/voice_chat/domain/entities/chat_message.dart';
import 'package:echo_lingua/features/voice_chat/domain/repositories/voice_chat_repository.dart';
import 'package:echo_lingua/features/voice_chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:echo_lingua/features/voice_chat/presentation/cubit/voice_chat_cubit.dart';

class MockSendMessageStreamUseCase extends Mock
    implements SendMessageStreamUseCase {}

class MockAudioRepository extends Mock implements AudioRepository {}

class MockVoiceChatRepository extends Mock implements VoiceChatRepository {}

void main() {
  late MockSendMessageStreamUseCase mockSendUseCase;
  late MockAudioRepository mockAudioRepo;
  late MockVoiceChatRepository mockVoiceChatRepo;
  late VoiceChatCubit cubit;

  setUp(() {
    mockSendUseCase = MockSendMessageStreamUseCase();
    mockAudioRepo = MockAudioRepository();
    mockVoiceChatRepo = MockVoiceChatRepository();

    when(() => mockAudioRepo.isSpeakingStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioRepo.soundLevelStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioRepo.stopSpeaking()).thenAnswer((_) async {});
    when(() => mockAudioRepo.stopListening()).thenAnswer((_) async {});
    when(() => mockAudioRepo.startListening(locale: any(named: 'locale')))
        .thenAnswer((_) => const Stream.empty());

    cubit = VoiceChatCubit(
      sendMessageStreamUseCase: mockSendUseCase,
      audioRepository: mockAudioRepo,
      voiceChatRepository: mockVoiceChatRepo,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state has empty messages and not busy', () {
    expect(cubit.state.messages, isEmpty);
    expect(cubit.state.isBusy, isFalse);
    expect(cubit.state.isListening, isFalse);
  });

  test(
    'sendMessage appends user message and placeholder assistant message',
    () async {
      when(
        () => mockSendUseCase(
          history: any(named: 'history'),
          systemPrompt: any(named: 'systemPrompt'),
        ),
      ).thenAnswer((_) => Stream.fromIterable(['Hello', '!']));

      when(
        () => mockAudioRepo.speak(
          any(),
          locale: any(named: 'locale'),
          rate: any(named: 'rate'),
          voiceGender: any(named: 'voiceGender'),
        ),
      ).thenAnswer((_) async {});

      await cubit.sendMessage(
        content: 'Hi teacher',
        systemPrompt: 'Be a tutor',
        ttsLocale: 'en-US',
      );

      // Wait a brief microtask for stream completion
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.messages.length, equals(2));
      expect(cubit.state.messages[0].isUser, isTrue);
      expect(cubit.state.messages[0].content, equals('Hi teacher'));
      expect(cubit.state.messages[1].isUser, isFalse);
      expect(cubit.state.messages[1].content, equals('Hello!'));
    },
  );

  test('toggleAutoPlayTts toggles state flag', () {
    expect(cubit.state.autoPlayTts, isFalse);
    cubit.toggleAutoPlayTts();
    expect(cubit.state.autoPlayTts, isTrue);
  });

  test('startLiveMode enters live mode and starts listening', () async {
    await cubit.startLiveMode(
      systemPrompt: 'Teach Japanese',
      ttsLocale: 'ja-JP',
      sttLocale: 'ja_JP',
      voiceGender: 'male',
      speechRate: 0.6,
    );

    expect(cubit.state.isLiveMode, isTrue);
    expect(cubit.state.liveStatus, equals('listening'));
    verify(() => mockAudioRepo.startListening(locale: 'ja_JP')).called(1);
  });

  test('stopLiveMode terminates live mode and resets state', () async {
    await cubit.startLiveMode(
      systemPrompt: 'Teach English',
      ttsLocale: 'en-US',
      sttLocale: 'en_US',
    );
    expect(cubit.state.isLiveMode, isTrue);

    await cubit.stopLiveMode();
    expect(cubit.state.isLiveMode, isFalse);
    expect(cubit.state.liveStatus, equals('idle'));
    verify(() => mockAudioRepo.stopSpeaking()).called(greaterThanOrEqualTo(1));
    verify(() => mockAudioRepo.stopListening()).called(greaterThanOrEqualTo(1));
  });

  test('bargeIn starts listening again when in live mode', () async {
    await cubit.startLiveMode(
      systemPrompt: 'Teach English',
      ttsLocale: 'en-US',
      sttLocale: 'en_US',
    );
    await cubit.bargeIn();

    expect(cubit.state.liveStatus, equals('listening'));
    verify(() => mockAudioRepo.startListening(locale: 'en_US')).called(2);
  });

  test(
    'stopListeningOnly returns recognized text and ends listening state',
    () async {
      when(() => mockAudioRepo.startListening(locale: any(named: 'locale')))
          .thenAnswer((_) => Stream.value('Recognized voice draft'));

      await cubit.startListening(locale: 'en_US');
      // Allow stream to emit
      await Future.delayed(const Duration(milliseconds: 10));

      final text = await cubit.stopListeningOnly();
      expect(text, equals('Recognized voice draft'));
      expect(cubit.state.isListening, isFalse);
      expect(cubit.state.partialRecognizedText, isEmpty);
    },
  );

  test(
    'playMessageAudio passes voiceGender and rate to audioRepository',
    () async {
      when(
        () => mockAudioRepo.speak(
          any(),
          locale: any(named: 'locale'),
          rate: any(named: 'rate'),
          voiceGender: any(named: 'voiceGender'),
        ),
      ).thenAnswer((_) async {});

      final msg = cubit.state.messages.isNotEmpty
          ? cubit.state.messages.first
          : ChatMessage(
              id: 'test_msg',
              content: 'Audio test',
              isUser: false,
              timestamp: DateTime.now(),
            );

      await cubit.playMessageAudio(
        msg,
        locale: 'en-US',
        voiceGender: 'male',
        rate: 0.7,
      );

      verify(
        () => mockAudioRepo.speak(
          'Audio test',
          locale: 'en-US',
          rate: 0.7,
          voiceGender: 'male',
        ),
      ).called(1);
    },
  );
}
