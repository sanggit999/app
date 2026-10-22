import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_lingua/features/audio/domain/repositories/audio_repository.dart';
import 'package:echo_lingua/features/language/data/language_registry.dart';
import 'package:echo_lingua/features/language/domain/entities/language_profile.dart';
import 'package:echo_lingua/features/llm/data/services/adaptive_llm_service.dart';
import 'package:echo_lingua/features/llm/data/services/model_manager.dart';
import 'package:echo_lingua/features/llm/domain/services/llm_service.dart';

import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences sharedPreferences;
  final LlmService llmService;
  final AudioRepository? audioRepository;
  final ModelManager? modelManager;

  StreamSubscription<ModelDownloadProgress>? _downloadSubscription;

  static const String _keyBaseUrl = 'ollama_base_url';
  static const String _keyModel = 'ollama_model';
  static const String _keyRate = 'tts_speech_rate';
  static const String _keyVoiceGender = 'voice_gender';
  static const String _keyLang = 'target_language_code';

  SettingsCubit({
    required this.sharedPreferences,
    required this.llmService,
    this.audioRepository,
    this.modelManager,
  }) : super(const SettingsState()) {
    _initListeners();
    _loadPreferences();
  }

  void _initListeners() {
    _downloadSubscription = modelManager?.progressStream.listen((prog) {
      if (prog.error != null) {
        emit(
          state.copyWith(
            isDownloadingModel: false,
            downloadStatusText: 'Lỗi tải: ${prog.error}',
          ),
        );
      } else if (prog.isCompleted) {
        emit(
          state.copyWith(
            isDownloadingModel: false,
            isModelDownloaded: true,
            downloadProgress: 1.0,
            downloadStatusText: 'Tải hoàn tất! Model sẵn sàng 100%.',
          ),
        );
        testConnection();
      } else {
        emit(
          state.copyWith(
            isDownloadingModel: true,
            downloadProgress: prog.fraction,
            downloadStatusText:
                '${prog.receivedMb} MB / ${prog.totalMb} MB (${prog.percent}%)',
          ),
        );
      }
    });
  }

  Future<void> _loadPreferences() async {
    final mode =
        sharedPreferences.getString(AdaptiveLlmService.keyExecutionMode) ??
        'ollama';
    final baseUrl =
        sharedPreferences.getString(_keyBaseUrl) ?? 'http://127.0.0.1:11434';
    final model = sharedPreferences.getString(_keyModel) ?? 'qwen2.5:3b';
    final rate = sharedPreferences.getDouble(_keyRate) ?? 0.5;
    final gender = sharedPreferences.getString(_keyVoiceGender) ?? 'female';
    final langCode = sharedPreferences.getString(_keyLang) ?? 'en';
    final profile = LanguageRegistry.getProfile(langCode);

    final isDownloaded = await modelManager?.isModelDownloaded() ?? false;

    emit(
      state.copyWith(
        executionMode: mode,
        ollamaBaseUrl: baseUrl,
        modelName: model,
        speechRate: rate,
        voiceGender: gender,
        currentLanguage: profile,
        isModelDownloaded: isDownloaded,
      ),
    );

    testConnection();
  }

  Future<void> updateExecutionMode(String mode) async {
    await sharedPreferences.setString(
      AdaptiveLlmService.keyExecutionMode,
      mode,
    );
    emit(state.copyWith(executionMode: mode));
    await testConnection();
  }

  Future<void> startModelDownload() async {
    if (modelManager == null || state.isDownloadingModel) return;
    emit(
      state.copyWith(
        isDownloadingModel: true,
        downloadProgress: 0.0,
        downloadStatusText:
            'Đang kết nối tải mô hình Qwen 2.5 0.5B (~350MB)...',
      ),
    );

    try {
      await modelManager!.downloadModel();
    } catch (_) {
      // Error handled by stream
    }
  }

  Future<void> deleteModel() async {
    await modelManager?.deleteModel();
    emit(
      state.copyWith(
        isModelDownloaded: false,
        downloadProgress: 0.0,
        downloadStatusText: '',
      ),
    );
    await testConnection();
  }

  Future<void> updateBaseUrl(String url) async {
    final cleaned = url.trim();
    await sharedPreferences.setString(_keyBaseUrl, cleaned);
    emit(state.copyWith(ollamaBaseUrl: cleaned));
    await testConnection();
  }

  Future<void> updateModel(String model) async {
    final cleaned = model.trim();
    await sharedPreferences.setString(_keyModel, cleaned);
    emit(state.copyWith(modelName: cleaned));
  }

  Future<void> updateSpeechRate(double rate) async {
    await sharedPreferences.setDouble(_keyRate, rate);
    emit(state.copyWith(speechRate: rate));
  }

  Future<void> updateVoiceGender(String gender) async {
    await sharedPreferences.setString(_keyVoiceGender, gender);
    emit(state.copyWith(voiceGender: gender));
  }

  Future<void> testVoicePlayback() async {
    final isMale = state.voiceGender == 'male';
    final sampleText = isMale
        ? 'Hello! I am your AI English tutor. Nice to meet you!'
        : 'Hi there! I am your English coach. Glad to talk with you!';
    await audioRepository?.speak(
      sampleText,
      locale: state.currentLanguage.ttsLocale,
      rate: state.speechRate,
      voiceGender: state.voiceGender,
    );
  }

  Future<void> selectLanguage(LanguageProfile profile) async {
    await sharedPreferences.setString(_keyLang, profile.code);
    emit(state.copyWith(currentLanguage: profile));
  }

  Future<void> testConnection() async {
    emit(
      state.copyWith(
        connectionStatus: ConnectionStatus.checking,
        clearConnectionError: true,
      ),
    );

    if (state.isOnDevice) {
      final isReady = await modelManager?.isModelDownloaded() ?? false;
      if (isReady) {
        emit(
          state.copyWith(
            connectionStatus: ConnectionStatus.connected,
            isModelDownloaded: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            connectionStatus: ConnectionStatus.failed,
            isModelDownloaded: false,
            connectionError:
                'Mô hình On-Device chưa được tải về máy (Cần tải ~350MB).',
          ),
        );
      }
      return;
    }

    try {
      final isHealthy = await llmService.checkHealth();
      if (isHealthy) {
        emit(state.copyWith(connectionStatus: ConnectionStatus.connected));
      } else {
        emit(
          state.copyWith(
            connectionStatus: ConnectionStatus.failed,
            connectionError:
                'Server at ${state.ollamaBaseUrl} did not respond.',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          connectionStatus: ConnectionStatus.failed,
          connectionError: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
