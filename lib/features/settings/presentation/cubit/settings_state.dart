import 'package:equatable/equatable.dart';
import 'package:echo_lingua/features/language/data/language_registry.dart';
import 'package:echo_lingua/features/language/domain/entities/language_profile.dart';

enum ConnectionStatus { unknown, checking, connected, failed }

class SettingsState extends Equatable {
  final String executionMode; // 'ollama' or 'on_device'
  final String ollamaBaseUrl;
  final String modelName;
  final double speechRate;
  final String voiceGender;
  final LanguageProfile currentLanguage;
  final ConnectionStatus connectionStatus;
  final String? connectionError;
  final bool isModelDownloaded;
  final bool isDownloadingModel;
  final double downloadProgress;
  final String downloadStatusText;

  const SettingsState({
    this.executionMode = 'ollama',
    this.ollamaBaseUrl = 'http://127.0.0.1:11434',
    this.modelName = 'qwen2.5:3b',
    this.speechRate = 0.5,
    this.voiceGender = 'female',
    this.currentLanguage = LanguageRegistry.english,
    this.connectionStatus = ConnectionStatus.unknown,
    this.connectionError,
    this.isModelDownloaded = false,
    this.isDownloadingModel = false,
    this.downloadProgress = 0.0,
    this.downloadStatusText = '',
  });

  bool get isOnDevice => executionMode == 'on_device';

  SettingsState copyWith({
    String? executionMode,
    String? ollamaBaseUrl,
    String? modelName,
    double? speechRate,
    String? voiceGender,
    LanguageProfile? currentLanguage,
    ConnectionStatus? connectionStatus,
    String? connectionError,
    bool clearConnectionError = false,
    bool? isModelDownloaded,
    bool? isDownloadingModel,
    double? downloadProgress,
    String? downloadStatusText,
  }) {
    return SettingsState(
      executionMode: executionMode ?? this.executionMode,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      modelName: modelName ?? this.modelName,
      speechRate: speechRate ?? this.speechRate,
      voiceGender: voiceGender ?? this.voiceGender,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectionError: clearConnectionError
          ? null
          : (connectionError ?? this.connectionError),
      isModelDownloaded: isModelDownloaded ?? this.isModelDownloaded,
      isDownloadingModel: isDownloadingModel ?? this.isDownloadingModel,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadStatusText: downloadStatusText ?? this.downloadStatusText,
    );
  }

  @override
  List<Object?> get props => [
    executionMode,
    ollamaBaseUrl,
    modelName,
    speechRate,
    voiceGender,
    currentLanguage,
    connectionStatus,
    connectionError,
    isModelDownloaded,
    isDownloadingModel,
    downloadProgress,
    downloadStatusText,
  ];
}
