import '../entities/translation_result.dart';
import '../repositories/translation_repository.dart';

class TranslateTextUseCase {
  final TranslationRepository repository;

  TranslateTextUseCase(this.repository);

  Future<TranslationResult> call({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const TranslationResult(originalText: '', translatedText: '');
    }
    return repository.translate(
      text: trimmed,
      sourceLang: sourceLang,
      targetLang: targetLang,
    );
  }
}
