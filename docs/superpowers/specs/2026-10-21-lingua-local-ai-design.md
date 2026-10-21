# LinguaLocal AI - On-Device AI Language Learning & Translation App
**Architecture & Design Specification**

- **Author**: Senior Mobile Architect & Senior UI/UX Specialist
- **Date**: 2026-10-21
- **Target Platform**: Flutter (Android, iOS, Desktop/Windows)
- **Architecture**: Clean Architecture (Domain, Data, Presentation)
- **State Management**: BLoC / Cubit (`flutter_bloc`)
- **Key Capabilities**: Local LLM Inference (Offline/LAN streaming), On-Device STT (Speech-to-Text), On-Device TTS (Text-to-Speech), Multi-language Extensibility.

---

## 1. Executive Summary & Intent

LinguaLocal AI là ứng dụng di động hỗ trợ học ngoại ngữ và dịch thuật thông minh toàn diện, vận hành dựa trên **mô hình ngôn ngữ lớn cục bộ (Local LLM)** nhằm bảo vệ tối đa tính riêng tư dữ liệu, không phát sinh chi phí API cloud, và hoạt động mượt mà với độ trễ thấp.

Ứng dụng khởi đầu tập trung vào cặp ngôn ngữ **Tiếng Anh - Tiếng Việt**, nhưng kiến trúc lõi được trừu tượng hóa (Language Strategy Pattern) để mở rộng dễ dàng sang các ngôn ngữ khác (Tiếng Nhật, Tiếng Hàn, Tiếng Trung, Tiếng Tây Ban Nha,...).

---

## 2. Trải Nghiệm Người Dùng (Senior UI/UX Design System)

### 2.1. Triết lý Thiết Kế
- **Immersive & Tactile (Sống động và phản hồi trực giác)**: Giao diện học tiếng Anh đòi hỏi sự tự tin khi nói. Nút ghi âm micro và nút loa phát âm được thiết kế nổi bật, có hiệu ứng lan tỏa (pulse/ripple) và sóng âm (waveform visualizer) thời gian thực theo âm lượng giọng nói.
- **Micro-Learning & Scaffolding**: Mỗi phản hồi của AI không chỉ là văn bản đơn thuần mà được bóc tách thành:
  1. Câu thoại tự nhiên kèm audio TTS.
  2. Phiên âm chuẩn quốc tế (IPA).
  3. Gợi ý sửa lỗi ngữ pháp/phát âm nhẹ nhàng (Grammar & Accent coaching).
  4. Quick action buttons: "Dịch nhanh", "Nghe chậm lại 0.8x", "Lưu vào sổ tay từ vựng".

### 2.2. Bảng Màu & Typography
- **Primary Color**: Electric Indigo (`#4F46E5` / `#3B82F6`) — thể hiện sự hiện đại, công nghệ và tập trung.
- **Secondary / Aura Color**: Cyan / Teal (`#06B6D4`) — thể hiện năng lượng giao tiếp và tươi sáng.
- **Accent / Alert**: Amber Coral (`#F59E0B` / `#EF4444`) — dùng cho điểm số phát âm, lưu từ vựng hoặc cảnh báo.
- **Neutral Dark Mode**: Slate Dark (`#0F172A` background, `#1E293B` card surfaces).
- **Neutral Light Mode**: Ice White (`#F8FAFC` background, `#FFFFFF` card surfaces).
- **Typography**: Google Font `DM Sans` cho nội dung hội thoại dễ đọc, kết hợp `Space Grotesk` hoặc `Inter` cho headers và số liệu.

### 2.3. Các Màn Hình Chính
1. **Live AI Voice Tutor (Hội thoại trực tiếp)**:
   - Giao diện trung tâm là vòng tròn sóng âm tương tác (Interactive Wave Visualizer).
   - Nút Micro dạng Floating/Push-to-Talk kích thước 72x72px ở đáy màn hình, viền phát sáng khi đang ghi âm.
   - Luồng hội thoại thời gian thực (streaming text token-by-token khi LLM trả lời).
   - Nút loa tích hợp ngay cạnh từng tin nhắn với trạng thái: Đang phát (sóng âm nhỏ), Đã dừng.
2. **Smart Translator & Grammar Analyzer (Dịch thuật ngữ cảnh)**:
   - Hộp nhập văn bản hoặc nút nói bằng tiếng Việt/tiếng Anh.
   - Thẻ kết quả dịch kèm phân tích ngữ pháp (Part of speech, Collocations, Synonyms).
   - Chuyển đổi ngôn ngữ mục tiêu (Target Language Selector) 1 chạm.
3. **Vocabulary Notebook (Sổ tay từ vựng & Spaced Repetition)**:
   - Danh sách các từ và cấu trúc đã lưu trong quá trình chat/dịch.
   - Nghe lại phát âm, xem ví dụ và trạng thái ôn tập.
4. **Settings & Local Model Config**:
   - Cấu hình địa chỉ Local LLM (mặc định Ollama `http://10.0.2.2:11434` cho Android Emulator, `http://localhost:11434` cho Desktop/iOS).
   - Chọn model (vd: `llama3.2:3b`, `gemma2:2b`, `qwen2.5:3b`).
   - Tùy chỉnh tốc độ nói TTS (0.5x - 1.5x) và giọng đọc.

---

## 3. Kiến Trúc Kỹ Thuật (Clean Architecture & Cubit)

Tuân thủ nguyên tắc độc lập giữa các tầng:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  - Views (VoiceChatView, TranslatorView, SettingsView)      │
│  - Cubits & States (VoiceChatCubit, TranslatorCubit, etc.)  │
│  - Reusable Widgets (AudioWaveform, PulsingMicButton)       │
└──────────────────────────────┬──────────────────────────────┘
                               │ calls usecases
┌──────────────────────────────▼──────────────────────────────┐
│                      Domain Layer                           │
│  - Entities (ChatMessage, TranslationResult, Persona)        │
│  - Repository Interfaces (LlmRepository, AudioRepository)   │
│  - Use Cases (SendVoiceMessage, TranslateText, SpeakAudio)  │
└──────────────────────────────▲──────────────────────────────┘
                               │ implements interfaces
┌──────────────────────────────┴──────────────────────────────┐
│                       Data Layer                            │
│  - Data Sources (OllamaLlmDataSource, SttDataSource,        │
│                  TtsDataSource, LocalStorageDataSource)     │
│  - Models (OllamaStreamChunkModel, TranslationDto)          │
│  - Repository Implementations (LlmRepositoryImpl, ...)      │
└─────────────────────────────────────────────────────────────┘
```

### 3.1. Phân Tầng Chi Tiết

#### Tầng Data (Data Layer)
- `LlmLocalDataSource`: Kết nối tới Ollama / llama local server qua HTTP/SSE streaming (`/api/generate` hoặc `/api/chat`). Đọc chunk dữ liệu stream thời gian thực.
- `SpeechToTextDataSource`: Bọc thư viện `speech_to_text`, phát ra stream kết quả nhận diện giọng nói và mức âm lượng (`soundLevel`).
- `TextToSpeechDataSource`: Bọc `flutter_tts`, quản lý phát audio, chỉnh ngôn ngữ, tốc độ phát, và callback khi hoàn tất câu nói.
- `StorageDataSource`: Lưu lịch sử hội thoại và từ vựng offline bằng `shared_preferences` hoặc `hive`.

#### Tầng Domain (Domain Layer)
- Độc lập hoàn toàn với framework và thư viện bên ngoài.
- `LlmRepository`:
  - `Stream<String> streamChat({required List<ChatMessage> history, required String systemPrompt})`
  - `Future<TranslationResult> translate({required String text, required String sourceLang, required String targetLang})`
- `AudioRepository`:
  - `Future<void> speak({required String text, required String languageCode, double speed})`
  - `Future<void> stopSpeaking()`
  - `Stream<SpeechRecognitionResult> startListening({required String languageCode})`
  - `Future<void> stopListening()`
- Use Cases:
  - `ProcessVoiceInteractionUseCase`: Điều phối luồng (User nói -> STT -> LLM Stream -> TTS đọc).
  - `TranslateUseCase`: Gửi prompt có cấu trúc JSON tới LLM để trích xuất nghĩa, phiên âm và ví dụ.

#### Tầng Presentation (Presentation Layer)
- Quản lý trạng thái bằng **Cubit**:
  - `VoiceChatCubit`:
    - States: `VoiceChatInitial`, `VoiceChatListening(partialText, soundLevel)`, `VoiceChatThinking`, `VoiceChatStreaming(currentReply, fullHistory)`, `VoiceChatSpeaking(speakingMessageId)`, `VoiceChatError(message)`.
  - `TranslatorCubit`:
    - States: `TranslatorInitial`, `TranslatorLoading`, `TranslatorSuccess(TranslationResult)`, `TranslatorError(message)`.
  - `SettingsCubit`: Quản lý model name, base URL, ngôn ngữ học tập.

---

## 4. Multi-Language Extensibility Strategy (Chiến Lược Mở Rộng Đa Ngôn Ngữ)

Tạo interface `LanguageProfile`:
```dart
class LanguageProfile {
  final String code; // 'en', 'vi', 'ja', 'ko', 'zh', 'es'
  final String displayName;
  final String ttsLocale; // 'en-US', 'vi-VN', 'ja-JP', ...
  final String sttLocale;
  final String systemPromptTemplate;
}
```
Khi người dùng chọn học tiếng Anh, profile Anh được nạp kèm system prompt chuyên dụng cho giáo viên tiếng Anh (có giải thích bằng tiếng Việt). Khi chuyển sang tiếng Nhật/Hàn/Trung, hệ thống chỉ cần thay đổi `LanguageProfile` tương ứng mà không phải sửa đổi bất kỳ dòng code logic nào.

---

## 5. Non-Goals & Failure Modes (Rủi Ro & Giới Hạn Cần Tránh)

- **Non-Goals ban đầu**: Không huấn luyện model từ đầu (tận dụng open-weights models tối ưu cho ngôn ngữ như Llama 3.2 3B, Qwen 2.5 3B, Gemma 2 2B).
- **Rủi ro 1 - Kết nối Local LLM gián đoạn**: Nếu local server chưa khởi động, app phải phát hiện ngay lập tức và hiển thị hướng dẫn trực quan (Check IP / Start Ollama) thay vì treo vô tận.
- **Rủi ro 2 - Xung đột Audio (Echo/Feedback)**: Khi TTS đang phát thì microphone không được ghi âm lại giọng nói của bot (Acoustic Echo). Cần cơ chế khóa micro hoặc tự động tạm dừng TTS khi người dùng bấm nói.
- **Rủi ro 3 - Latency của Local LLM**: Cần cơ chế Stream Token để người dùng thấy chữ xuất hiện ngay lập tức sau ~500ms thay vì đợi toàn bộ câu trả lời 3-5 giây.
