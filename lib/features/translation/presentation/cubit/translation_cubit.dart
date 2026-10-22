import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/translate_text_usecase.dart';
import 'translation_state.dart';

class TranslationCubit extends Cubit<TranslationState> {
  final TranslateTextUseCase translateUseCase;

  TranslationCubit({required this.translateUseCase})
    : super(const TranslationInitial());

  Future<void> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (text.trim().isEmpty) {
      emit(const TranslationInitial());
      return;
    }

    emit(const TranslationLoading());

    try {
      final result = await translateUseCase(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );
      emit(
        TranslationSuccess(
          result: result,
          sourceLang: sourceLang,
          targetLang: targetLang,
        ),
      );
    } catch (e) {
      emit(TranslationError(message: e.toString()));
    }
  }

  void clear() {
    emit(const TranslationInitial());
  }
}
