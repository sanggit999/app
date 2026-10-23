import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/device_profile_service.dart';

// Audio
import '../../features/audio/data/repositories/audio_repository_impl.dart';
import '../../features/audio/data/services/flutter_tts_service.dart';
import '../../features/audio/data/services/speech_to_text_service.dart';
import '../../features/audio/domain/repositories/audio_repository.dart';
import '../../features/audio/domain/services/stt_service.dart';
import '../../features/audio/domain/services/tts_service.dart';

// LLM
import '../../features/llm/data/services/adaptive_llm_service.dart';
import '../../features/llm/data/services/model_manager.dart';
import '../../features/llm/data/services/ollama_llm_service.dart';
import '../../features/llm/data/services/on_device_llm_service.dart';
import '../../features/llm/domain/services/llm_service.dart';

// Translation
import '../../features/translation/data/repositories/translation_repository_impl.dart';
import '../../features/translation/domain/repositories/translation_repository.dart';
import '../../features/translation/domain/usecases/translate_text_usecase.dart';
import '../../features/translation/presentation/cubit/translation_cubit.dart';

// Voice Chat
import '../../features/voice_chat/data/repositories/voice_chat_repository_impl.dart';
import '../../features/voice_chat/domain/repositories/voice_chat_repository.dart';
import '../../features/voice_chat/domain/usecases/send_message_stream_usecase.dart';
import '../../features/voice_chat/presentation/cubit/voice_chat_cubit.dart';

// Settings
import '../../features/settings/presentation/cubit/settings_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 1. External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // 2. Core & Services
  sl.registerLazySingleton<ModelManager>(
    () => ModelManager(client: sl<http.Client>()),
  );

  sl.registerLazySingleton<OllamaLlmService>(
    () => OllamaLlmService(
      client: sl<http.Client>(),
      baseUrl:
          sl<SharedPreferences>().getString('ollama_base_url') ??
          'http://127.0.0.1:11434',
      defaultModel:
          sl<SharedPreferences>().getString('ollama_model') ?? 'qwen2.5:3b',
    ),
  );

  sl.registerLazySingleton<OnDeviceLlmService>(
    () => OnDeviceLlmService(modelManager: sl<ModelManager>()),
  );

  sl.registerLazySingleton<LlmService>(
    () => AdaptiveLlmService(
      ollamaService: sl<OllamaLlmService>(),
      onDeviceService: sl<OnDeviceLlmService>(),
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  sl.registerLazySingleton<TtsService>(() => FlutterTtsService());
  sl.registerLazySingleton<SttService>(() => SpeechToTextService());

  // 3. Repositories
  sl.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(
      ttsService: sl<TtsService>(),
      sttService: sl<SttService>(),
    ),
  );

  sl.registerLazySingleton<TranslationRepository>(
    () => TranslationRepositoryImpl(llmService: sl<LlmService>()),
  );

  sl.registerLazySingleton<VoiceChatRepository>(
    () => VoiceChatRepositoryImpl(llmService: sl<LlmService>()),
  );

  // 4. Use Cases
  sl.registerLazySingleton<TranslateTextUseCase>(
    () => TranslateTextUseCase(sl<TranslationRepository>()),
  );

  sl.registerLazySingleton<SendMessageStreamUseCase>(
    () => SendMessageStreamUseCase(sl<VoiceChatRepository>()),
  );

  // 5. Cubits (Factory for state lifecycle)
  sl.registerFactory<VoiceChatCubit>(
    () => VoiceChatCubit(
      sendMessageStreamUseCase: sl<SendMessageStreamUseCase>(),
      audioRepository: sl<AudioRepository>(),
      voiceChatRepository: sl<VoiceChatRepository>(),
    ),
  );

  sl.registerFactory<TranslationCubit>(
    () => TranslationCubit(translateUseCase: sl<TranslateTextUseCase>()),
  );

  sl.registerLazySingleton<DeviceProfileService>(() => DeviceProfileService());

  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      sharedPreferences: sl<SharedPreferences>(),
      llmService: sl<LlmService>(),
      audioRepository: sl<AudioRepository>(),
      modelManager: sl<ModelManager>(),
      deviceProfileService: sl<DeviceProfileService>(),
    ),
  );
}
