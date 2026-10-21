import 'package:equatable/equatable.dart';
import '../../domain/entities/translation_result.dart';

abstract class TranslationState extends Equatable {
  const TranslationState();

  @override
  List<Object?> get props => [];
}

class TranslationInitial extends TranslationState {
  const TranslationInitial();
}

class TranslationLoading extends TranslationState {
  const TranslationLoading();
}

class TranslationSuccess extends TranslationState {
  final TranslationResult result;
  final String sourceLang;
  final String targetLang;

  const TranslationSuccess({
    required this.result,
    required this.sourceLang,
    required this.targetLang,
  });

  @override
  List<Object?> get props => [result, sourceLang, targetLang];
}

class TranslationError extends TranslationState {
  final String message;

  const TranslationError({required this.message});

  @override
  List<Object?> get props => [message];
}
