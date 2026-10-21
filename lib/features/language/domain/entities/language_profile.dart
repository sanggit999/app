import 'package:equatable/equatable.dart';

class LanguageProfile extends Equatable {
  final String code; // 'en', 'vi', 'ja', 'ko', 'zh', 'es'
  final String name; // 'English', 'Tiếng Việt', 'Japanese', ...
  final String nativeName;
  final String flagEmoji;
  final String ttsLocale; // 'en-US', 'vi-VN', 'ja-JP', ...
  final String sttLocale; // 'en_US', 'vi_VN', 'ja_JP', ...
  final String defaultSystemPrompt;

  const LanguageProfile({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    required this.ttsLocale,
    required this.sttLocale,
    required this.defaultSystemPrompt,
  });

  @override
  List<Object?> get props => [
        code,
        name,
        nativeName,
        flagEmoji,
        ttsLocale,
        sttLocale,
        defaultSystemPrompt,
      ];
}
