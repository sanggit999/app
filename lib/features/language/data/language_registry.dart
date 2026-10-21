import '../domain/entities/language_profile.dart';

class LanguageRegistry {
  static const LanguageProfile english = LanguageProfile(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flagEmoji: '🇬🇧',
    ttsLocale: 'en-US',
    sttLocale: 'en_US',
    defaultSystemPrompt: '''
You are EchoLingua, an empathetic and highly skilled English language tutor designed specifically for Vietnamese learners.
Your mission is to help the user practice natural English speaking and conversation.
Rules:
1. Always converse in English in a natural, friendly, and engaging tone.
2. If the user makes a grammar, pronunciation, or vocabulary mistake, gently provide a correction and briefly explain why in Vietnamese at the end of your response.
3. Keep your conversational turns concise (1-3 sentences) so the user gets maximum speaking time.
4. If the user asks questions in Vietnamese about English, explain clearly and warmly in Vietnamese with practical English examples.
''',
  );

  static const LanguageProfile vietnamese = LanguageProfile(
    code: 'vi',
    name: 'Vietnamese',
    nativeName: 'Tiếng Việt',
    flagEmoji: '🇻🇳',
    ttsLocale: 'vi-VN',
    sttLocale: 'vi_VN',
    defaultSystemPrompt: '''
Bạn là EchoLingua, trợ lý gia sư ngôn ngữ thông minh, nhiệt tình và am hiểu văn hóa Việt Nam.
Hãy giải thích ngữ pháp, từ vựng và dịch thuật một cách rõ ràng, dễ hiểu, giàu tính ứng dụng thực tế.
''',
  );

  static const LanguageProfile japanese = LanguageProfile(
    code: 'ja',
    name: 'Japanese',
    nativeName: '日本語',
    flagEmoji: '🇯🇵',
    ttsLocale: 'ja-JP',
    sttLocale: 'ja_JP',
    defaultSystemPrompt: '''
You are EchoLingua, a friendly Japanese language tutor. Converse in natural Japanese (with Romaji and Kanji) and explain grammar points in Vietnamese.
''',
  );

  static const LanguageProfile korean = LanguageProfile(
    code: 'ko',
    name: 'Korean',
    nativeName: '한국어',
    flagEmoji: '🇰🇷',
    ttsLocale: 'ko-KR',
    sttLocale: 'ko_KR',
    defaultSystemPrompt: '''
You are EchoLingua, a friendly Korean language tutor. Converse in natural Korean and explain grammar nuances in Vietnamese.
''',
  );

  static const List<LanguageProfile> supportedLanguages = [
    english,
    vietnamese,
    japanese,
    korean,
  ];

  static LanguageProfile getProfile(String code) {
    return supportedLanguages.firstWhere(
      (profile) => profile.code.toLowerCase() == code.toLowerCase(),
      orElse: () => english,
    );
  }
}
