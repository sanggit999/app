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
  final bool isDownloadPaused;
  final double downloadProgress;
  final String downloadStatusText;
  final bool hasPartialDownload;
  final String partialDownloadedMb;

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
    this.isDownloadPaused = false,
    this.downloadProgress = 0.0,
    this.downloadStatusText = '',
    this.hasPartialDownload = false,
    this.partialDownloadedMb = '0.0',
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
    bool? isDownloadPaused,
    double? downloadProgress,
    String? downloadStatusText,
    bool? hasPartialDownload,
    String? partialDownloadedMb,
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
      isDownloadPaused: isDownloadPaused ?? this.isDownloadPaused,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadStatusText: downloadStatusText ?? this.downloadStatusText,
      hasPartialDownload: hasPartialDownload ?? this.hasPartialDownload,
      partialDownloadedMb: partialDownloadedMb ?? this.partialDownloadedMb,
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
    isDownloadPaused,
    downloadProgress,
    downloadStatusText,
    hasPartialDownload,
    partialDownloadedMb,
  ];
}
