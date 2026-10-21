import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:echo_lingua/features/translation/domain/entities/translation_result.dart';
import 'package:echo_lingua/features/translation/domain/usecases/translate_text_usecase.dart';
import 'package:echo_lingua/features/translation/presentation/cubit/translation_cubit.dart';
import 'package:echo_lingua/features/translation/presentation/cubit/translation_state.dart';

class MockTranslateUseCase extends Mock implements TranslateTextUseCase {}

void main() {
  late MockTranslateUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockTranslateUseCase();
  });

  const tResult = TranslationResult(
    originalText: 'Hello',
    translatedText: 'Xin chào',
    phonetic: '/həˈloʊ/',
    explanation: 'Lời chào thân mật',
    examples: ['Hello everyone!'],
  );

  blocTest<TranslationCubit, TranslationState>(
    'emits [Loading, Success] when translation succeeds',
    build: () {
      when(() => mockUseCase(
            text: any(named: 'text'),
            sourceLang: any(named: 'sourceLang'),
            targetLang: any(named: 'targetLang'),
          )).thenAnswer((_) async => tResult);
      return TranslationCubit(translateUseCase: mockUseCase);
    },
    act: (cubit) => cubit.translate(text: 'Hello', sourceLang: 'en', targetLang: 'vi'),
    expect: () => [
      const TranslationLoading(),
      const TranslationSuccess(
        result: tResult,
        sourceLang: 'en',
        targetLang: 'vi',
      ),
    ],
  );

  blocTest<TranslationCubit, TranslationState>(
    'emits [Loading, Error] when translation fails',
    build: () {
      when(() => mockUseCase(
            text: any(named: 'text'),
            sourceLang: any(named: 'sourceLang'),
            targetLang: any(named: 'targetLang'),
          )).thenThrow(Exception('Server unreachable'));
      return TranslationCubit(translateUseCase: mockUseCase);
    },
    act: (cubit) => cubit.translate(text: 'Hello', sourceLang: 'en', targetLang: 'vi'),
    expect: () => [
      const TranslationLoading(),
      isA<TranslationError>(),
    ],
  );
}
