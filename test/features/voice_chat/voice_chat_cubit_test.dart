import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:echo_lingua/features/audio/domain/repositories/audio_repository.dart';
import 'package:echo_lingua/features/voice_chat/domain/repositories/voice_chat_repository.dart';
import 'package:echo_lingua/features/voice_chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:echo_lingua/features/voice_chat/presentation/cubit/voice_chat_cubit.dart';

class MockSendMessageStreamUseCase extends Mock implements SendMessageStreamUseCase {}
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

    when(() => mockAudioRepo.isSpeakingStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioRepo.soundLevelStream).thenAnswer((_) => const Stream.empty());
    when(() => mockAudioRepo.stopSpeaking()).thenAnswer((_) async {});

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

  test('sendMessage appends user message and placeholder assistant message', () async {
    when(() => mockSendUseCase(
          history: any(named: 'history'),
          systemPrompt: any(named: 'systemPrompt'),
        )).thenAnswer((_) => Stream.fromIterable(['Hello', '!']));

    when(() => mockAudioRepo.speak(
          any(),
          locale: any(named: 'locale'),
        )).thenAnswer((_) async {});

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
  });

  test('toggleAutoPlayTts toggles state flag', () {
    expect(cubit.state.autoPlayTts, isTrue);
    cubit.toggleAutoPlayTts();
    expect(cubit.state.autoPlayTts, isFalse);
  });
}
