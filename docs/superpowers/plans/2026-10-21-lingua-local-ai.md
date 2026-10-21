# LinguaLocal AI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng ứng dụng Flutter hoàn chỉnh (Clean Architecture + Cubit) sử dụng Local LLM để học và dịch tiếng Anh, tích hợp ghi âm đàm thoại trực tiếp (STT) và phát âm giọng nói (TTS) theo chuẩn UI/UX cao cấp, có khả năng mở rộng sang các ngôn ngữ khác.

**Architecture:** Áp dụng Clean Architecture chia 3 tầng độc lập (Data, Domain, Presentation). Tầng Presentation sử dụng BLoC / Cubit (`flutter_bloc`) để quản lý trạng thái luồng hội thoại streaming và audio. Tầng Data kết nối với Local LLM (Ollama stream reader) và native on-device audio services (`speech_to_text`, `flutter_tts`). Dependency Injection quản lý tập trung qua `get_it`.

**Tech Stack:** 
- Framework: Flutter (Dart 3.x)
- State Management: `flutter_bloc` (Cubit)
- Architecture: Clean Architecture + Repository Pattern
- Audio STT / TTS: `speech_to_text`, `flutter_tts`
- Local LLM: Ollama HTTP streaming client (hoạt động offline/LAN)
- Design Tokens: Google Fonts (`dm_sans`, `space_grotesk`), `flutter_svg`, custom Waveform & Ripple animations
- Testing: `flutter_test`, `mocktail`, `bloc_test`

**Spec:** [docs/superpowers/specs/2026-10-21-lingua-local-ai-design.md](file:///d:/app/docs/superpowers/specs/2026-10-21-lingua-local-ai-design.md)

---

## Global Constraints

- **Platform Compatibility**: Chạy mượt mà trên Android, iOS và Windows Desktop.
- **No Cloud Dependency**: Toàn bộ luồng hội thoại và dịch thuật ưu tiên xử lý qua Local LLM và on-device STT/TTS.
- **Strict Clean Architecture**: Tầng Domain không phụ thuộc vào bất kỳ package bên ngoài nào của Flutter UI hoặc thư viện HTTP/Audio cụ thể.
- **High UX Standards**: Nút ghi âm kích thước chuẩn ≥ 56px, có phản hồi thị giác sóng âm (waveform) và hiệu ứng chuyển đổi trạng thái mượt mà (150-250ms).
- **Zero Lint Errors**: Mọi file Dart phải tuân thủ chuẩn `flutter analyze`.

## Review Focus

1. **Local LLM Offline/Unreachable**: Khi địa chỉ server local (ví dụ `127.0.0.1:11434`) không phản hồi, Cubit phải bắt lỗi thân thiện và thông báo cấu hình IP thay vì crash app.
2. **Audio Feedback Loop (Echo)**: Khi người dùng bấm nói, hệ thống phải tự động ngắt TTS đang phát để tránh micro ghi âm lại giọng nói của bot.
3. **Stream Cancellation**: Khi người dùng nhấn nút ngắt câu hỏi hoặc đổi màn hình, stream kết nối với Local LLM phải được hủy sạch sẽ để tránh rò rỉ bộ nhớ.
4. **Permission Denied Handling**: Khi quyền Microphone bị từ chối, ứng dụng phải hiển thị hướng dẫn cấp quyền rõ ràng và không treo trạng thái recording.
5. **Multi-Language Switch**: Khi người dùng chuyển đổi ngôn ngữ mục tiêu (Anh sang Nhật/Hàn/...), TTS locale và System Prompt phải đồng bộ ngay lập tức.

---

### Task 1: Project Scaffolding, Dependencies & Design System

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_typography.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `test/core/theme/app_theme_test.dart`

**Interfaces:**
- Produces: `AppColors`, `AppTypography`, `AppTheme.darkTheme`, `AppTheme.lightTheme`

- [ ] **Step 1: Write the failing test for AppTheme**
```dart
// test/core/theme/app_theme_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_local/core/theme/app_theme.dart';
import 'package:lingua_local/core/theme/app_colors.dart';

void main() {
  test('AppTheme defines consistent primary colors and dark/light themes', () {
    expect(AppColors.primary, isNotNull);
    expect(AppTheme.darkTheme.primaryColor, equals(AppColors.primary));
    expect(AppTheme.lightTheme.primaryColor, equals(AppColors.primary));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: FAIL with compilation errors (classes not defined)

- [ ] **Step 3: Initialize Flutter project and configure `pubspec.yaml`**
Chạy `flutter create --org com.lingualocal --project-name lingua_local .` và cập nhật các dependencies: `flutter_bloc`, `equatable`, `http`, `speech_to_text`, `flutter_tts`, `get_it`, `shared_preferences`, `google_fonts`, `mocktail`, `bloc_test`.
Triển khai `AppColors`, `AppTypography`, `AppTheme`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add pubspec.yaml lib/core/theme/ test/core/theme/
git commit -m "feat: scaffold project with design tokens and theme"
```

---

### Task 2: Core Errors, Failure Handling & Service Locator (DI)

**Files:**
- Create: `lib/core/errors/failures.dart`
- Create: `lib/core/errors/exceptions.dart`
- Create: `lib/core/di/injection.dart`
- Test: `test/core/errors/failures_test.dart`

**Interfaces:**
- Produces: `abstract class Failure`, `ServerFailure`, `AudioFailure`, `NetworkFailure`, `sl` (GetIt instance)

- [ ] **Step 1: Write the failing test**
```dart
// test/core/errors/failures_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_local/core/errors/failures.dart';

void main() {
  test('ServerFailure holds message and supports value equality', () {
    final f1 = ServerFailure(message: 'Connection failed');
    final f2 = ServerFailure(message: 'Connection failed');
    expect(f1, equals(f2));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/errors/failures_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement Failures, Exceptions, and Service Locator**
Triển khai các lớp `Failure`, `ServerException`, `AudioException` kế thừa `Equatable`, và khởi tạo hàm `setupLocator()` trong `lib/core/di/injection.dart`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/core/errors/failures_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/core/errors/ lib/core/di/ test/core/errors/
git commit -m "feat: implement core errors and dependency injection container"
```

---

### Task 3: Multi-Language Strategy & Language Profiles

**Files:**
- Create: `lib/features/language/domain/entities/language_profile.dart`
- Create: `lib/features/language/data/language_registry.dart`
- Test: `test/features/language/language_registry_test.dart`

**Interfaces:**
- Produces: `class LanguageProfile`, `class LanguageRegistry` (`getProfile(String code)`, `supportedLanguages`)

- [ ] **Step 1: Write the failing test**
```dart
// test/features/language/language_registry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_local/features/language/data/language_registry.dart';

void main() {
  test('LanguageRegistry returns default English profile and supported list', () {
    final profile = LanguageRegistry.getProfile('en');
    expect(profile.name, equals('English'));
    expect(profile.ttsLocale, equals('en-US'));
    expect(profile.sttLocale, equals('en_US'));
    expect(LanguageRegistry.supportedLanguages.length, greaterThanOrEqualTo(2));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/language/language_registry_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement LanguageProfile and LanguageRegistry**
Định nghĩa `LanguageProfile` chứa code, name, ttsLocale, sttLocale, defaultSystemPrompt cho việc học tiếng Anh, tiếng Nhật, tiếng Hàn, tiếng Việt.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/language/language_registry_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/language/ test/features/language/
git commit -m "feat: add multi-language registry and profile strategy"
```

---

### Task 4: Local LLM Service (Streaming & Prompt Engine)

**Files:**
- Create: `lib/features/llm/domain/services/llm_service.dart`
- Create: `lib/features/llm/data/services/ollama_llm_service.dart`
- Create: `lib/features/llm/data/models/ollama_chat_request.dart`
- Test: `test/features/llm/ollama_llm_service_test.dart`

**Interfaces:**
- Produces: `abstract class LlmService` with `Stream<String> streamChat(...)`, `Future<String> generate(...)`, `Future<bool> checkHealth(...)`

- [ ] **Step 1: Write the failing test with Mock HTTP Client**
```dart
// test/features/llm/ollama_llm_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:lingua_local/features/llm/data/services/ollama_llm_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late OllamaLlmService service;

  setUp(() {
    mockClient = MockHttpClient();
    service = OllamaLlmService(client: mockClient, baseUrl: 'http://127.0.0.1:11434', model: 'llama3.2');
  });

  test('streamChat parses streaming json lines from Ollama response', () async {
    final streamResponse = http.StreamedResponse(
      Stream.fromIterable([
        utf8.encode('{"message":{"content":"Hello"},"done":false}\n'),
        utf8.encode('{"message":{"content":" world"},"done":true}\n'),
      ]),
      200,
    );

    when(() => mockClient.send(any())).thenAnswer((_) async => streamResponse);

    final tokens = await service.streamChat(prompt: 'Hi', systemPrompt: 'Tutor').toList();
    expect(tokens, equals(['Hello', ' world']));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/llm/ollama_llm_service_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement OllamaLlmService with robust stream decoding**
Xử lý `http.Request('POST', Uri.parse('$baseUrl/api/chat'))`, pipe stream qua `utf8.decoder` và `LineSplitter()`, parse từng JSON chunk trả về `message.content`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/llm/ollama_llm_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/llm/ test/features/llm/
git commit -m "feat: implement streaming local LLM service for Ollama"
```

---

### Task 5: Audio Engine (On-Device STT & TTS Service)

**Files:**
- Create: `lib/features/audio/domain/services/tts_service.dart`
- Create: `lib/features/audio/domain/services/stt_service.dart`
- Create: `lib/features/audio/data/services/flutter_tts_service.dart`
- Create: `lib/features/audio/data/services/speech_to_text_service.dart`
- Create: `lib/features/audio/domain/repositories/audio_repository.dart`
- Create: `lib/features/audio/data/repositories/audio_repository_impl.dart`
- Test: `test/features/audio/audio_repository_test.dart`

**Interfaces:**
- Produces: `AudioRepository`:
  - `Future<void> speak(String text, {required String locale, double rate})`
  - `Future<void> stopSpeaking()`
  - `Stream<String> startListening({required String locale})`
  - `Stream<double> get soundLevelStream`
  - `Future<void> stopListening()`

- [ ] **Step 1: Write the failing test for AudioRepositoryImpl**
```dart
// test/features/audio/audio_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lingua_local/features/audio/domain/services/tts_service.dart';
import 'package:lingua_local/features/audio/domain/services/stt_service.dart';
import 'package:lingua_local/features/audio/data/repositories/audio_repository_impl.dart';

class MockTtsService extends Mock implements TtsService {}
class MockSttService extends Mock implements SttService {}

void main() {
  test('startListening stops TTS first to prevent acoustic echo', () async {
    final tts = MockTtsService();
    final stt = MockSttService();
    when(() => tts.stop()).thenAnswer((_) async {});
    when(() => stt.startListening(locale: any(named: 'locale'))).thenAnswer((_) => Stream.value('hello'));

    final repo = AudioRepositoryImpl(ttsService: tts, sttService: stt);
    await repo.startListening(locale: 'en-US').first;

    verify(() => tts.stop()).called(1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/audio/audio_repository_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement Audio Services and AudioRepositoryImpl**
Bọc `flutter_tts` và `speech_to_text` vào các service riêng biệt, đảm bảo logic khóa chéo (ngắt TTS khi bắt đầu nghe microphone).

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/audio/audio_repository_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/audio/ test/features/audio/
git commit -m "feat: implement STT and TTS audio repository with echo prevention"
```

---

### Task 6: Smart Translation & Grammar Analyzer Feature (Clean Architecture + Cubit)

**Files:**
- Create: `lib/features/translation/domain/entities/translation_result.dart`
- Create: `lib/features/translation/domain/repositories/translation_repository.dart`
- Create: `lib/features/translation/domain/usecases/translate_text_usecase.dart`
- Create: `lib/features/translation/data/repositories/translation_repository_impl.dart`
- Create: `lib/features/translation/presentation/cubit/translation_cubit.dart`
- Create: `lib/features/translation/presentation/cubit/translation_state.dart`
- Test: `test/features/translation/translation_cubit_test.dart`

**Interfaces:**
- Produces: `TranslationCubit`, `TranslateTextUseCase`, `TranslationResult`

- [ ] **Step 1: Write the failing test for TranslationCubit**
```dart
// test/features/translation/translation_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lingua_local/features/translation/domain/entities/translation_result.dart';
import 'package:lingua_local/features/translation/domain/usecases/translate_text_usecase.dart';
import 'package:lingua_local/features/translation/presentation/cubit/translation_cubit.dart';
import 'package:lingua_local/features/translation/presentation/cubit/translation_state.dart';

class MockTranslateUseCase extends Mock implements TranslateTextUseCase {}

void main() {
  late MockTranslateUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockTranslateUseCase();
  });

  blocTest<TranslationCubit, TranslationState>(
    'emits [Loading, Success] when translate succeeds',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => const TranslationResult(
        originalText: 'Hello',
        translatedText: 'Xin chào',
        phonetic: '/həˈloʊ/',
        explanation: 'Lời chào thân thiện',
        examples: ['Hello world'],
      ));
      return TranslationCubit(translateUseCase: mockUseCase);
    },
    act: (cubit) => cubit.translate(text: 'Hello', sourceLang: 'en', targetLang: 'vi'),
    expect: () => [
      isA<TranslationLoading>(),
      isA<TranslationSuccess>(),
    ],
  );
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/translation/translation_cubit_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement Translation Entity, UseCase, Repository, and Cubit**
Tạo prompt yêu cầu LLM trả về cấu trúc JSON chứa `{ translatedText, phonetic, explanation, examples }`, parse kết quả thành `TranslationResult`, emit qua `TranslationCubit`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/translation/translation_cubit_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/translation/ test/features/translation/
git commit -m "feat: implement translation domain, repository and cubit"
```

---

### Task 7: Live AI Voice Tutor Feature (Clean Architecture + Cubit)

**Files:**
- Create: `lib/features/voice_chat/domain/entities/chat_message.dart`
- Create: `lib/features/voice_chat/domain/repositories/voice_chat_repository.dart`
- Create: `lib/features/voice_chat/domain/usecases/send_message_stream_usecase.dart`
- Create: `lib/features/voice_chat/data/repositories/voice_chat_repository_impl.dart`
- Create: `lib/features/voice_chat/presentation/cubit/voice_chat_cubit.dart`
- Create: `lib/features/voice_chat/presentation/cubit/voice_chat_state.dart`
- Test: `test/features/voice_chat/voice_chat_cubit_test.dart`

**Interfaces:**
- Produces: `VoiceChatCubit` with methods:
  - `startListening()`
  - `stopListeningAndSend()`
  - `sendTextMessage(String text)`
  - `playMessageAudio(ChatMessage message)`
  - `stopAudio()`

- [ ] **Step 1: Write the failing test for VoiceChatCubit**
```dart
// test/features/voice_chat/voice_chat_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lingua_local/features/voice_chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:lingua_local/features/audio/domain/repositories/audio_repository.dart';
import 'package:lingua_local/features/voice_chat/presentation/cubit/voice_chat_cubit.dart';
import 'package:lingua_local/features/voice_chat/presentation/cubit/voice_chat_state.dart';

class MockSendMessageStreamUseCase extends Mock implements SendMessageStreamUseCase {}
class MockAudioRepository extends Mock implements AudioRepository {}

void main() {
  late MockSendMessageStreamUseCase mockSendUseCase;
  late MockAudioRepository mockAudioRepo;

  setUp(() {
    mockSendUseCase = MockSendMessageStreamUseCase();
    mockAudioRepo = MockAudioRepository();
  });

  blocTest<VoiceChatCubit, VoiceChatState>(
    'streams reply tokens and updates message list',
    build: () {
      when(() => mockSendUseCase(any())).thenAnswer((_) => Stream.fromIterable(['Hi', ' there!']));
      return VoiceChatCubit(sendMessageStreamUseCase: mockSendUseCase, audioRepository: mockAudioRepo);
    },
    act: (cubit) => cubit.sendTextMessage('Hello'),
    expect: () => [
      isA<VoiceChatThinking>(),
      isA<VoiceChatStreaming>(),
      isA<VoiceChatIdle>(),
    ],
  );
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/voice_chat/voice_chat_cubit_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement VoiceChatCubit with comprehensive streaming state machine**
Xử lý `ChatMessage` (id, content, isUser, timestamp, isStreaming, isPlayingAudio). Khi nhận audio stream từ STT, cập nhật `liveRecognizedText`; khi hoàn tất, trigger LLM streaming và tùy chọn tự động phát TTS.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/voice_chat/voice_chat_cubit_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/voice_chat/ test/features/voice_chat/
git commit -m "feat: implement voice chat streaming cubit and state machine"
```

---

### Task 8: Senior UI Components (Pulsing Mic, Audio Waveform & Action Bubbles)

**Files:**
- Create: `lib/features/voice_chat/presentation/widgets/pulsing_mic_button.dart`
- Create: `lib/features/voice_chat/presentation/widgets/audio_wave_visualizer.dart`
- Create: `lib/features/voice_chat/presentation/widgets/chat_message_bubble.dart`
- Create: `lib/features/voice_chat/presentation/widgets/audio_play_button.dart`
- Test: `test/features/voice_chat/presentation/widgets/pulsing_mic_button_test.dart`

**Interfaces:**
- Produces:
  - `PulsingMicButton({required bool isListening, required VoidCallback onPressed, required double soundLevel})`
  - `AudioWaveVisualizer({required bool isActive, required Color color, int barCount = 16})`
  - `ChatMessageBubble({required ChatMessage message, required VoidCallback onPlayAudio, required VoidCallback onTranslate})`

- [ ] **Step 1: Write widget test for PulsingMicButton**
```dart
// test/features/voice_chat/presentation/widgets/pulsing_mic_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_local/features/voice_chat/presentation/widgets/pulsing_mic_button.dart';

void main() {
  testWidgets('PulsingMicButton renders and triggers callback on tap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PulsingMicButton(
          isListening: false,
          soundLevel: 0.0,
          onPressed: () => tapped = true,
        ),
      ),
    ));

    expect(find.byType(PulsingMicButton), findsOneWidget);
    await tester.tap(find.byType(PulsingMicButton));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/voice_chat/presentation/widgets/pulsing_mic_button_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement PulsingMicButton and UI Widgets with custom animations**
Tạo hiệu ứng lan tỏa (ripple) nhiều lớp bằng `AnimationController`, thanh sóng âm `CustomPainter` mượt mà, bóng đổ đổ màu theo bảng màu Indigo & Cyan.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/voice_chat/presentation/widgets/pulsing_mic_button_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/voice_chat/presentation/widgets/ test/features/voice_chat/presentation/widgets/
git commit -m "feat: implement animated audio widgets and message bubble"
```

---

### Task 9: Screen Assembly, App Navigation & Settings Management

**Files:**
- Create: `lib/features/settings/presentation/cubit/settings_cubit.dart`
- Create: `lib/features/settings/presentation/views/settings_screen.dart`
- Create: `lib/features/translation/presentation/views/translation_screen.dart`
- Create: `lib/features/voice_chat/presentation/views/voice_chat_screen.dart`
- Create: `lib/features/home/presentation/views/main_navigation_screen.dart`
- Create: `lib/main.dart`
- Test: `test/features/home/main_navigation_screen_test.dart`

**Interfaces:**
- Produces: `MainNavigationScreen` tích hợp Bottom Navigation Bar chuyển đổi mượt mà giữa:
  1. Live Voice Tutor (`VoiceChatScreen`)
  2. Smart Translator (`TranslationScreen`)
  3. Settings & Model Config (`SettingsScreen`)

- [ ] **Step 1: Write integration widget test for Navigation**
```dart
// test/features/home/main_navigation_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_local/features/home/presentation/views/main_navigation_screen.dart';

void main() {
  testWidgets('MainNavigationScreen displays navigation items and switches tabs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));
    expect(find.byIcon(Icons.record_voice_over), findsOneWidget);
    expect(find.byIcon(Icons.translate), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/home/main_navigation_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement Screens and Main Navigation**
Hoàn thiện giao diện các màn hình với `BlocProvider`, kết nối Cubit vào UI, hỗ trợ chuyển đổi ngôn ngữ mục tiêu (Tiếng Anh mặc định, hỗ trợ chọn Tiếng Nhật/Hàn/...), cài đặt IP Local LLM và kiểm tra trạng thái kết nối (Health check indicator).

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/home/main_navigation_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/ test/features/home/
git commit -m "feat: assemble screens, navigation bar, and main entrypoint"
```

---

### Task 10: End-to-End Verification & Quality Polish

**Files:**
- Verify: All tests across project
- Verify: Static analysis via `flutter analyze`
- Create: `README.md` (Hướng dẫn chạy app, kết nối Ollama/Local LLM, cấu hình mic và mở rộng ngôn ngữ mới)

- [ ] **Step 1: Run comprehensive test suite**
Run: `flutter test`
Expected: ALL TESTS PASS

- [ ] **Step 2: Run static code analysis**
Run: `flutter analyze`
Expected: No issues found!

- [ ] **Step 3: Write complete user guide and architectural documentation in `README.md`**
Cung cấp hướng dẫn từng bước:
- Chạy Local LLM: `ollama run llama3.2:3b`
- Cấu hình IP cho Android Emulator (`10.0.2.2:11434`) hoặc thiết bị thật qua WiFi LAN
- Cách thức hoạt động của tính năng đàm thoại trực tiếp (Voice Live Chat) và nút loa phát âm (TTS)
- Cách thêm ngôn ngữ mới chỉ với 5 dòng cấu hình trong `LanguageRegistry`.

- [ ] **Step 4: Commit**
```bash
git add README.md
git commit -m "docs: add comprehensive architecture and running guide"
```
