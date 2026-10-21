import '../entities/translation_result.dart';

abstract class TranslationRepository {
  Future<TranslationResult> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  });
}
