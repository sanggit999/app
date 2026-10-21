# EchoLingua AI 🎙️🧠
**Ứng Dụng Học Ngoại Ngữ & Dịch Thuật Đàm Thoại Trực Tiếp Sử Dụng Local LLM**

EchoLingua AI là ứng dụng Flutter được xây dựng theo chuẩn **Clean Architecture** kết hợp state management **BLoC / Cubit**, cho phép bạn đàm thoại trực tiếp bằng giọng nói (Live Voice Chat), phát âm tức thì (TTS), nhận diện giọng nói (STT), và dịch thuật chuyên sâu với sự hỗ trợ của mô hình ngôn ngữ lớn chạy **hoàn toàn cục bộ (Local LLM)**.

---

## 🌟 Tính Năng Nổi Bật (Key Features)

1. **Live AI Voice Tutor (Hội thoại đàm thoại trực tiếp):**
   - **Bấm ghi âm để nói (STT):** Nhận diện giọng nói tức thì với hiệu ứng sóng âm thời gian thực (**Waveform Visualizer**) và nút micro lan tỏa (**Pulsing Mic Button**).
   - **Local LLM Stream:** Phản hồi dạng streaming chữ xuất hiện từng từ (token-by-token) với độ trễ thấp qua mô hình cục bộ (khuyến nghị **Qwen 2.5 3B** hiểu tiếng Việt sâu sắc).
   - **Bấm loa để nghe phát âm (TTS):** Bot tự động phát âm câu trả lời bằng giọng chuẩn bản xứ với độ trễ gần bằng 0 (On-device Text-To-Speech).
   - **Cơ chế chống Echo:** Tự động ngắt phát âm khi người dùng kích hoạt micro để tránh việc micro thu lại tiếng nói của bot.

2. **Smart Translator & Grammar Analyzer (Dịch thuật & Phân tích ngữ cảnh):**
   - Hỗ trợ nhập liệu bằng văn bản hoặc đọc bằng giọng nói.
   - Phân tích chi tiết: Nghĩa dịch, phiên âm chuẩn quốc tế **IPA**, phân loại từ (Noun/Verb/...), giải thích ngữ cảnh ngữ pháp bằng tiếng Việt, các câu ví dụ minh họa và từ đồng nghĩa.
   - Bấm loa phát âm cả câu gốc và câu dịch.

3. **Cấu hình Local LLM & Voice linh hoạt:**
   - Hỗ trợ đổi địa chỉ Host Ollama URL (`http://127.0.0.1:11434`, `http://10.0.2.2:11434` hoặc IP mạng LAN).
   - Huy hiệu kiểm tra trạng thái kết nối trực tiếp (Health Check Indicator).
   - Tùy chỉnh tốc độ đọc TTS (0.2x đến 1.0x).
   - Mở rộng đa ngôn ngữ qua **Language Strategy Pattern** (mặc định Tiếng Anh, sẵn sàng cho Tiếng Nhật, Hàn, Trung...).

---

## 🏛️ Kiến Trúc Hệ Thống (Clean Architecture + Cubit)

```text
lib/
├── core/
│   ├── di/               # Service Locator với GetIt (Dependency Injection)
│   ├── errors/           # Failures & Exceptions dùng chung
│   └── theme/            # Design System Tokens, Dark & Light Mode, AppTypography
│
├── features/
│   ├── audio/            # On-device STT (Speech-To-Text) & TTS (Text-To-Speech)
│   │   ├── data/         # SpeechToTextService, FlutterTtsService, AudioRepositoryImpl
│   │   └── domain/       # TtsService, SttService, AudioRepository
│   │
│   ├── llm/              # Local LLM Engine
│   │   ├── data/         # OllamaLlmService (SSE/NDJSON stream reader)
│   │   └── domain/       # LlmService abstract interface
│   │
│   ├── language/         # Multi-Language Strategy
│   │   ├── data/         # LanguageRegistry (English, Vietnamese, Japanese, Korean)
│   │   └── domain/       # LanguageProfile entity
│   │
│   ├── voice_chat/       # Live AI Voice Dialogue
│   │   ├── domain/       # ChatMessage, SendMessageStreamUseCase, VoiceChatRepository
│   │   ├── data/         # VoiceChatRepositoryImpl
│   │   └── presentation/ # VoiceChatCubit, PulsingMicButton, AudioWaveVisualizer, VoiceChatScreen
│   │
│   ├── translation/      # Smart Translation & Grammar Breakdown
│   │   ├── domain/       # TranslationResult, TranslateTextUseCase, TranslationRepository
│   │   ├── data/         # TranslationRepositoryImpl
│   │   └── presentation/ # TranslationCubit, TranslationScreen
│   │
│   ├── settings/         # Local LLM Host & Voice Settings
│   │   └── presentation/ # SettingsCubit, SettingsScreen
│   │
│   └── home/             # Main Navigation Bottom Bar
│       └── presentation/ # MainNavigationScreen
│
└── main.dart             # App Entrypoint & MultiBlocProvider
```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Bước 1: Khởi động Local LLM (Ollama)
Cài đặt [Ollama](https://ollama.com/) và tải mô hình khuyến nghị tối ưu nhất cho tiếng Việt và tiếng Anh:

```bash
ollama run qwen2.5:3b
```
*(Nếu muốn máy yếu hơn hoặc nhẹ hơn, bạn có thể chạy `ollama run qwen2.5:1.5b`)*

> **Lưu ý cấu hình IP truy cập nội bộ cho Ollama:**
> Mặc định Ollama chỉ lắng nghe `localhost`. Để ứng dụng di động trong mạng WiFi hoặc máy ảo truy cập được, đặt biến môi trường:
> - **Windows (PowerShell):** `$env:OLLAMA_HOST="0.0.0.0:11434"; ollama serve`
> - **macOS / Linux:** `OLLAMA_HOST=0.0.0.0:11434 ollama serve`

### Bước 2: Chạy Ứng Dụng Flutter

1. Cài đặt dependencies:
   ```bash
   flutter pub get
   ```

2. Chạy ứng dụng trên thiết bị mong muốn:
   - **Desktop Windows:**
     ```bash
     flutter run -d windows
     ```
   - **Android Emulator / Thiết bị Android thật:**
     ```bash
     flutter run -d android
     ```
     *(Trên Android Emulator, địa chỉ Host mặc định là `http://10.0.2.2:11434`)*
   - **iOS Simulator / iPhone:**
     ```bash
     flutter run -d ios
     ```

### Bước 3: Kiểm tra Test Suite
Chạy toàn bộ unit test và widget test để xác thực độ ổn định:
```bash
flutter test
```

---

## 🧪 Phân Tích & Chất Lượng Mã Nguồn
- Tuân thủ quy chuẩn nghiêm ngặt `flutter analyze`.
- Không sử dụng các biến kiểu `dynamic` bừa bãi; toàn bộ trạng thái được bảo vệ bằng immutability và `Equatable`.
- Tách biệt 100% logic nghiệp vụ khỏi giao diện để dễ dàng thay thế engine suy luận (ví dụ chuyển sang FFI `llama.cpp` nhúng thẳng vào file APK khi cần).
