import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:echo_lingua/features/home/presentation/views/main_navigation_screen.dart';
import 'package:echo_lingua/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:echo_lingua/features/settings/presentation/cubit/settings_state.dart';
import 'package:echo_lingua/features/voice_chat/presentation/cubit/voice_chat_cubit.dart';
import 'package:echo_lingua/features/voice_chat/presentation/cubit/voice_chat_state.dart';
import 'package:echo_lingua/features/translation/presentation/cubit/translation_cubit.dart';
import 'package:echo_lingua/features/translation/presentation/cubit/translation_state.dart';

class MockSettingsCubit extends Mock implements SettingsCubit {}
class MockVoiceChatCubit extends Mock implements VoiceChatCubit {}
class MockTranslationCubit extends Mock implements TranslationCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsCubit mockSettingsCubit;
  late MockVoiceChatCubit mockVoiceChatCubit;
  late MockTranslationCubit mockTranslationCubit;

  setUp(() {
    mockSettingsCubit = MockSettingsCubit();
    mockVoiceChatCubit = MockVoiceChatCubit();
    mockTranslationCubit = MockTranslationCubit();

    when(() => mockSettingsCubit.state).thenReturn(const SettingsState());
    when(() => mockSettingsCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockVoiceChatCubit.state).thenReturn(const VoiceChatState());
    when(() => mockVoiceChatCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockTranslationCubit.state).thenReturn(const TranslationInitial());
    when(() => mockTranslationCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('MainNavigationScreen displays 3 navigation destinations', (tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
          BlocProvider<VoiceChatCubit>.value(value: mockVoiceChatCubit),
          BlocProvider<TranslationCubit>.value(value: mockTranslationCubit),
        ],
        child: const MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );

    expect(find.text('Luyện Nói'), findsOneWidget);
    expect(find.text('Dịch Thuật'), findsOneWidget);
    expect(find.text('Cài Đặt'), findsOneWidget);
  });

  testWidgets('MainNavigationScreen collapses bottom navigation bar when keyboard is open', (tester) async {
    // Simulate keyboard open by setting viewInsets
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
          BlocProvider<VoiceChatCubit>.value(value: mockVoiceChatCubit),
          BlocProvider<TranslationCubit>.value(value: mockTranslationCubit),
        ],
        child: const MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final animatedContainer = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(animatedContainer.constraints?.maxHeight, 0.0);

    // Reset view
    tester.view.resetViewInsets();
  });
}
