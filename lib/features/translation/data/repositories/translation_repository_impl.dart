import 'dart:convert';

import 'package:echo_lingua/core/errors/exceptions.dart';
import 'package:echo_lingua/features/llm/domain/services/llm_service.dart';
import 'package:echo_lingua/features/translation/domain/entities/translation_result.dart';
import 'package:echo_lingua/features/translation/domain/repositories/translation_repository.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  final LlmService llmService;

  TranslationRepositoryImpl({required this.llmService});

  @override
  Future<TranslationResult> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final systemPrompt =
        '''
You are an expert bilingual translator, phonetician and language tutor.
Translate the input text from $sourceLang to $targetLang accurately.
You MUST output ONLY a valid JSON object without markdown wrapper or other commentary, in this exact format:
{
  "translatedText": "translated content",
  "phonetic": "IPA phonetic transcription (for English/target language)",
  "partOfSpeech": "noun/verb/adjective/phrase/sentence",
  "explanation": "clear grammar or nuance explanation in Vietnamese",
  "examples": ["example sentence 1", "example sentence 2"],
  "synonyms": ["synonym 1", "synonym 2"]
}
''';

    try {
      final rawResponse = await llmService.generate(
        prompt: text,
        systemPrompt: systemPrompt,
      );

      return _parseJsonTranslation(text, rawResponse);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Translation error: $e');
    }
  }

  TranslationResult _parseJsonTranslation(String originalText, String raw) {
    try {
      // Find JSON block if model wraps in ```json ... ```
      String jsonStr = raw.trim();
      final startIndex = jsonStr.indexOf('{');
      final endIndex = jsonStr.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        jsonStr = jsonStr.substring(startIndex, endIndex + 1);
      }

      final Map<String, dynamic> map = jsonDecode(jsonStr);

      final List<String> examples =
          (map['examples'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final List<String> synonyms =
          (map['synonyms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return TranslationResult(
        originalText: originalText,
        translatedText: map['translatedText']?.toString() ?? raw.trim(),
        phonetic: map['phonetic']?.toString() ?? '',
        partOfSpeech: map['partOfSpeech']?.toString() ?? '',
        explanation: map['explanation']?.toString() ?? '',
        examples: examples,
        synonyms: synonyms,
      );
    } catch (_) {
      // Graceful fallback to raw translation
      return TranslationResult(
        originalText: originalText,
        translatedText: raw.trim(),
      );
    }
  }
}
