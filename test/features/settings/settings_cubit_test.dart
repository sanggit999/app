import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_lingua/features/audio/domain/repositories/audio_repository.dart';
import 'package:echo_lingua/features/llm/domain/services/llm_service.dart';
import 'package:echo_lingua/features/settings/presentation/cubit/settings_cubit.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockLlmService extends Mock implements LlmService {}
class MockAudioRepository extends Mock implements AudioRepository {}

void main() {
  late MockSharedPreferences mockPrefs;
  late MockLlmService mockLlmService;
  late MockAudioRepository mockAudioRepo;
  late SettingsCubit cubit;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockLlmService = MockLlmService();
    mockAudioRepo = MockAudioRepository();

    when(() => mockPrefs.getString('ollama_base_url')).thenReturn(null);
    when(() => mockPrefs.getString('ollama_model')).thenReturn(null);
    when(() => mockPrefs.getDouble('tts_speech_rate')).thenReturn(null);
    when(() => mockPrefs.getString('voice_gender')).thenReturn(null);
    when(() => mockPrefs.getString('target_language_code')).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockLlmService.checkHealth()).thenAnswer((_) async => true);

    cubit = SettingsCubit(
      sharedPreferences: mockPrefs,
      llmService: mockLlmService,
      audioRepository: mockAudioRepo,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('default state has female voiceGender and 0.5 speechRate', () {
    expect(cubit.state.voiceGender, equals('female'));
    expect(cubit.state.speechRate, equals(0.5));
  });

  test('updateVoiceGender saves to SharedPreferences and emits new state', () async {
    when(() => mockPrefs.setString('voice_gender', 'male'))
        .thenAnswer((_) async => true);

    await cubit.updateVoiceGender('male');

    expect(cubit.state.voiceGender, equals('male'));
    verify(() => mockPrefs.setString('voice_gender', 'male')).called(1);
  });

  test('testVoicePlayback triggers audioRepository speak with voiceGender', () async {
    when(() => mockAudioRepo.speak(
          any(),
          locale: any(named: 'locale'),
          rate: any(named: 'rate'),
          voiceGender: any(named: 'voiceGender'),
        )).thenAnswer((_) async {});

    await cubit.updateVoiceGender('male');
    await cubit.testVoicePlayback();

    verify(() => mockAudioRepo.speak(
          any(),
          locale: cubit.state.currentLanguage.ttsLocale,
          rate: cubit.state.speechRate,
          voiceGender: 'male',
        )).called(1);
  });
}
