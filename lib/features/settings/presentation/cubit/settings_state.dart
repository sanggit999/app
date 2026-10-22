import 'package:equatable/equatable.dart';
import 'package:echo_lingua/features/language/data/language_registry.dart';
import 'package:echo_lingua/features/language/domain/entities/language_profile.dart';

enum ConnectionStatus { unknown, checking, connected, failed }

class SettingsState extends Equatable {
  final String ollamaBaseUrl;
  final String modelName;
  final double speechRate;
  final String voiceGender;
  final LanguageProfile currentLanguage;
  final ConnectionStatus connectionStatus;
  final String? connectionError;

  const SettingsState({
    this.ollamaBaseUrl = 'http://127.0.0.1:11434',
    this.modelName = 'qwen2.5:3b',
    this.speechRate = 0.5,
    this.voiceGender = 'female',
    this.currentLanguage = LanguageRegistry.english,
    this.connectionStatus = ConnectionStatus.unknown,
    this.connectionError,
  });

  SettingsState copyWith({
    String? ollamaBaseUrl,
    String? modelName,
    double? speechRate,
    String? voiceGender,
    LanguageProfile? currentLanguage,
    ConnectionStatus? connectionStatus,
    String? connectionError,
    bool clearConnectionError = false,
  }) {
    return SettingsState(
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      modelName: modelName ?? this.modelName,
      speechRate: speechRate ?? this.speechRate,
      voiceGender: voiceGender ?? this.voiceGender,
      currentLanguage: currentLanguage ?? this.currentLanguage,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectionError: clearConnectionError
          ? null
          : (connectionError ?? this.connectionError),
    );
  }

  @override
  List<Object?> get props => [
        ollamaBaseUrl,
        modelName,
        speechRate,
        voiceGender,
        currentLanguage,
        connectionStatus,
        connectionError,
      ];
}
