import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_lingua/core/services/device_profile_service.dart';
import 'package:echo_lingua/features/audio/domain/repositories/audio_repository.dart';
import 'package:echo_lingua/features/language/data/language_registry.dart';
import 'package:echo_lingua/features/language/domain/entities/language_profile.dart';
import 'package:echo_lingua/features/llm/data/services/adaptive_llm_service.dart';
import 'package:echo_lingua/features/llm/data/services/model_manager.dart';
import 'package:echo_lingua/features/llm/data/services/ollama_llm_service.dart';
import 'package:echo_lingua/features/llm/domain/entities/real_model_spec.dart';
import 'package:echo_lingua/features/llm/domain/services/llm_service.dart';

import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences sharedPreferences;
  final LlmService llmService;
  final AudioRepository? audioRepository;
  final ModelManager? modelManager;
  final DeviceProfileService? deviceProfileService;

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
    this.deviceProfileService,
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
            isDownloadPaused: true,
            hasPartialDownload: prog.receivedBytes > 0,
            partialDownloadedMb: prog.receivedMb,
            downloadStatusText: 'Tạm dừng do mạng/lỗi. Bấm Tiếp Tục để tải tiếp.',
          ),
        );
      } else if (prog.isPaused) {
        emit(
          state.copyWith(
            isDownloadingModel: false,
            isDownloadPaused: true,
            hasPartialDownload: prog.receivedBytes > 0,
            partialDownloadedMb: prog.receivedMb,
            downloadProgress: prog.fraction,
            downloadStatusText:
                'Đã tạm dừng (${prog.receivedMb} MB / ${prog.totalMb} MB).',
          ),
        );
      } else if (prog.isCompleted) {
        emit(
          state.copyWith(
            isDownloadingModel: false,
            isDownloadPaused: false,
            isModelDownloaded: true,
            hasPartialDownload: false,
            downloadProgress: 1.0,
            downloadStatusText: 'Tải hoàn tất! Model sẵn sàng 100%.',
          ),
        );
        testConnection();
      } else {
        emit(
          state.copyWith(
            isDownloadingModel: true,
            isDownloadPaused: false,
            hasPartialDownload: true,
            partialDownloadedMb: prog.receivedMb,
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
    final partSizeBytes =
        await modelManager?.getPartialDownloadedSizeBytes() ?? 0;
    final hasPart = !isDownloaded && partSizeBytes > 0;
    final partMb = (partSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final approxFraction =
        hasPart ? (partSizeBytes / (360 * 1024 * 1024)).clamp(0.0, 1.0) : 0.0;

    DeviceProfile? deviceProfile;
    if (deviceProfileService != null) {
      deviceProfile = await deviceProfileService!.getDeviceProfile();
    }

    emit(
      state.copyWith(
        executionMode: mode,
        ollamaBaseUrl: baseUrl,
        modelName: model,
        speechRate: rate,
        voiceGender: gender,
        currentLanguage: profile,
        isModelDownloaded: isDownloaded,
        hasPartialDownload: hasPart,
        partialDownloadedMb: partMb,
        downloadProgress: approxFraction,
        downloadStatusText: hasPart
            ? 'Đang có bản tải dở ($partMb MB / ~360 MB). Bấm để tải tiếp.'
            : '',
        deviceProfile: deviceProfile,
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

    final initialText = state.hasPartialDownload
        ? 'Đang kết nối để tải tiếp từ ${state.partialDownloadedMb} MB...'
        : 'Đang kết nối tải mô hình Qwen 2.5 0.5B (~360MB)...';

    emit(
      state.copyWith(
        isDownloadingModel: true,
        isDownloadPaused: false,
        downloadStatusText: initialText,
      ),
    );

    try {
      await modelManager!.downloadModel();
    } catch (_) {
      // Error handled by stream
    }
  }

  void pauseOrCancelModelDownload() {
    if (modelManager == null || !state.isDownloadingModel) return;
    modelManager!.cancelOrPauseDownload();
  }

  Future<void> deleteModel() async {
    await modelManager?.deleteModel();
    emit(
      state.copyWith(
        isModelDownloaded: false,
        isDownloadingModel: false,
        isDownloadPaused: false,
        hasPartialDownload: false,
        partialDownloadedMb: '0.0',
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
    final lang = state.currentLanguage.code.toLowerCase();

    String sampleText;
    switch (lang) {
      case 'vi':
        sampleText = isMale
            ? 'Xin chào! Tôi là gia sư nam AI của bạn. Rất vui được đồng hành cùng bạn.'
            : 'Xin chào bạn! Mình là gia sư nữ AI. Rất vui được đồng hành cùng bạn.';
        break;
      case 'ja':
        sampleText = isMale
            ? 'こんにちは！AIの男性講師です。よろしくお願いします。'
            : 'こんにちは！AIの女性講師です。よろしくお願いします。';
        break;
      case 'ko':
        sampleText = isMale
            ? '안녕하세요! AI 남성 튜터입니다. 반갑습니다.'
            : '안녕하세요! AI 여성 튜터입니다. 반갑습니다.';
        break;
      case 'en':
      default:
        sampleText = isMale
            ? 'Hello! I am your male AI tutor. Nice to meet you.'
            : 'Hi there! I am your female AI coach. Glad to talk with you.';
        break;
    }

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

  void toggleSuggestedModelsExpanded() {
    emit(
      state.copyWith(
        isSuggestedModelsExpanded: !state.isSuggestedModelsExpanded,
      ),
    );
  }

  /// Quét lại cấu hình phần cứng thật và đánh giá tương thích với model AI thật
  Future<void> runDeviceHardwareCheck() async {
    debugPrint('\n============================================================');
    debugPrint('🔍 [HARDWARE_CHECK] Người dùng bấm: Kiểm tra máy hợp với model nào');
    emit(state.copyWith(isCheckingDeviceCompatibility: true));

    try {
      // 1. Quét mới cấu hình phần cứng thiết bị thời gian thực
      debugPrint('⏳ [HARDWARE_CHECK] Đang đọc tài nguyên phần cứng thời gian thực...');
      final profile = await (deviceProfileService?.refreshProfile() ??
          deviceProfileService?.getDeviceProfile());

      final ramAvailMb = profile?.availableRamMb ?? 2048;
      final totalRamMb = profile?.totalRamMb ?? 4096;
      final freeDiskMb = profile?.freeDiskMb ?? 5120;

      final ramAvailGb = (ramAvailMb / 1024).toStringAsFixed(1);
      final ramTotalGb = (totalRamMb / 1024).toStringAsFixed(1);
      final romFreeGb = (freeDiskMb / 1024).toStringAsFixed(1);

      debugPrint('📱 [DEVICE] Tên máy: ${profile?.deviceLabel} (${profile?.manufacturer})');
      debugPrint('💾 [RAM] Khả dụng: ${ramAvailMb.toStringAsFixed(0)} MB (~$ramAvailGb GB) / Tổng: ${totalRamMb.toStringAsFixed(0)} MB (~$ramTotalGb GB)');
      debugPrint('💽 [STORAGE] Dung lượng trống: ${freeDiskMb.toStringAsFixed(0)} MB (~$romFreeGb GB)');
      debugPrint('🏆 [TIER] Phân cấp phần cứng: ${profile?.tier.name.toUpperCase()}');

      // 2. Nếu ở chế độ Ollama, thử kết nối tới server để lấy model thật đã cài
      List<String> installedModels = [];
      debugPrint('⚙️ [MODE] Chế độ LLM: ${state.isOnDevice ? "On-Device (Cục bộ)" : "Máy chủ Ollama (${state.ollamaBaseUrl})"}');
      if (!state.isOnDevice) {
        debugPrint('🌐 [OLLAMA] Đang truy vấn danh sách model thật từ host: ${state.ollamaBaseUrl}/api/tags ...');
        try {
          if (llmService is AdaptiveLlmService) {
            installedModels = await (llmService as AdaptiveLlmService)
                .ollamaService
                .getInstalledModelNames();
          } else if (llmService is OllamaLlmService) {
            installedModels =
                await (llmService as OllamaLlmService).getInstalledModelNames();
          }
          debugPrint('✅ [OLLAMA] Model đã cài trên máy chủ: ${installedModels.isEmpty ? "Chưa có model nào hoặc máy chủ trống" : installedModels.join(", ")}');
        } catch (e) {
          debugPrint('⚠️ [OLLAMA] Không thể kết nối tới Ollama host: $e');
        }
      }

      // 3. Đánh giá tương thích chi tiết từng model trong RealModelCatalog
      debugPrint('📊 [COMPATIBILITY] Đánh giá tương thích từng mô hình với phần cứng hiện tại:');
      for (final spec in RealModelCatalog.realModels) {
        final suitability = spec.evaluate(ramAvailMb, freeDiskMb);
        final statusSymbol = switch (suitability) {
          ModelSuitability.optimal => '⚡ [RẤT MƯỢT]',
          ModelSuitability.compatible => '✓ [TƯƠNG THÍCH]',
          ModelSuitability.demanding => '⚠️ [NẶNG]',
          ModelSuitability.insufficient => '✕ [THIẾU RAM]',
        };
        debugPrint('   $statusSymbol ${spec.id.padRight(14)} (${spec.parameterSize.padRight(5)}) | Cần RAM: ${spec.ramRequirementDisplay.padRight(8)} | Trống: ${spec.storageRequirementDisplay.padRight(8)} -> ${spec.bestFor}');
      }

      String summary;
      if (state.isOnDevice) {
        if (ramAvailMb >= 1200 && freeDiskMb >= 1000) {
          summary =
              'Thiết bị có $ramAvailGb GB RAM khả dụng / $ramTotalGb GB ($romFreeGb GB trống). Đủ điều kiện chạy On-Device cực mượt mà không nóng máy!';
        } else {
          summary =
              'RAM khả dụng còn $ramAvailGb GB ($romFreeGb GB trống). Đề xuất dùng Qwen 2.5 0.5B hoặc chuyển sang Máy chủ Ollama.';
        }
      } else {
        if (installedModels.isNotEmpty) {
          summary =
              'Tìm thấy ${installedModels.length} model thật trên Ollama Host: ${installedModels.join(', ')}. Cấu hình thiết bị kết nối đàm thoại rất tốt.';
        } else {
          summary =
              'Thiết bị có $ramAvailGb GB RAM khả dụng ($romFreeGb GB trống). Đề xuất: qwen2.5:3b (Tiếng Việt xuất sắc) hoặc qwen2.5:1.5b (siêu nhẹ).';
        }
      }

      debugPrint('💡 [SUMMARY] $summary');
      debugPrint('============================================================\n');

      emit(
        state.copyWith(
          deviceProfile: profile,
          installedOllamaModels: installedModels,
          isCheckingDeviceCompatibility: false,
          deviceCheckSummary: summary,
          isSuggestedModelsExpanded: true,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [HARDWARE_CHECK] Gặp lỗi khi kiểm tra thiết bị: $e');
      debugPrint('$stackTrace');
      debugPrint('============================================================\n');
      emit(state.copyWith(isCheckingDeviceCompatibility: false));
    }
  }

  @override
  Future<void> close() {
    _downloadSubscription?.cancel();
    return super.close();
  }
}
