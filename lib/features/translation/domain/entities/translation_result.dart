import 'package:equatable/equatable.dart';

class TranslationResult extends Equatable {
  final String originalText;
  final String translatedText;
  final String phonetic;
  final String partOfSpeech;
  final String explanation;
  final List<String> examples;
  final List<String> synonyms;

  const TranslationResult({
    required this.originalText,
    required this.translatedText,
    this.phonetic = '',
    this.partOfSpeech = '',
    this.explanation = '',
    this.examples = const [],
    this.synonyms = const [],
  });

  @override
  List<Object?> get props => [
    originalText,
    translatedText,
    phonetic,
    partOfSpeech,
    explanation,
    examples,
    synonyms,
  ];
}
