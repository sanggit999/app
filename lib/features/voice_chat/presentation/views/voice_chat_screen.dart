import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';
import 'package:echo_lingua/core/theme/app_typography.dart';
import 'package:echo_lingua/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:echo_lingua/features/settings/presentation/cubit/settings_state.dart';
import 'package:echo_lingua/features/settings/presentation/views/settings_screen.dart';
import 'package:echo_lingua/features/voice_chat/presentation/cubit/voice_chat_cubit.dart';
import 'package:echo_lingua/features/voice_chat/presentation/cubit/voice_chat_state.dart';
import 'package:echo_lingua/features/voice_chat/presentation/widgets/chat_message_bubble.dart';
import 'package:echo_lingua/features/voice_chat/presentation/widgets/messenger_input_bar.dart';
import 'package:echo_lingua/features/voice_chat/presentation/widgets/live_voice_call_modal.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showPromptChips = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus &&
          _scrollController.hasClients &&
          _scrollController.offset > 0) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({int delayMs = 100}) {
    void doScroll() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    if (delayMs > 0) {
      Future.delayed(Duration(milliseconds: delayMs), doScroll);
    } else {
      doScroll();
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Cài đặt AI & Giọng nói'),
          ),
          body: const SettingsScreen(),
        ),
      ),
    );
  }

  bool _ensureLlmReady(BuildContext context, SettingsState settings) {
    if (settings.isLlmReady) {
      return true;
    }
    _showLlmNotReadySheet(context, settings);
    return false;
  }

  void _showLlmNotReadySheet(BuildContext context, SettingsState settings) {
    final settingsCubit = context.read<SettingsCubit>();
    final isOnDevice = settings.isOnDevice;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return BlocConsumer<SettingsCubit, SettingsState>(
          listener: (context, currentSettings) {
            if (currentSettings.isModelDownloaded) {
              Navigator.of(bottomSheetContext).maybePop();
            }
          },
          builder: (context, currentSettings) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final isDownloading = currentSettings.isDownloadingModel;
            final hasPart = currentSettings.hasPartialDownload;

            String title;
            String message;
            IconData headerIcon;
            Color iconColor;

            if (isOnDevice) {
              if (isDownloading) {
                title = 'Đang tải mô hình On-Device';
                message =
                    'Mô hình AI đang được tải về máy của bạn. Bạn có thể đóng cửa sổ này để theo dõi tiến độ tải trực tiếp ngay dưới thanh tiêu đề.';
                headerIcon = Icons.cloud_download_rounded;
                iconColor = AppColors.primary;
              } else if (hasPart) {
                title = 'Tải mô hình đang tạm dừng';
                message =
                    'Đã có sẵn ${currentSettings.partialDownloadedMb} MB dữ liệu tải trước. Bấm Tiếp tục tải để hệ thống tải tiếp ngầm và hiển thị tiến độ ở đầu trang.';
                headerIcon = Icons.pause_circle_outline_rounded;
                iconColor = AppColors.warning;
              } else {
                title = 'Chưa tải mô hình On-Device';
                message =
                    'EchoLingua sử dụng mô hình AI Qwen 2.5 0.5B (~350MB) chạy ngoại tuyến 100% riêng tư trên thiết bị. Bấm Tải ngay để bắt đầu tải và theo dõi tiến độ ở màn hình chính.';
                headerIcon = Icons.downloading_rounded;
                iconColor = AppColors.secondary;
              }
            } else {
              title = 'Chưa kết nối máy chủ Ollama';
              message =
                  'Không thể kết nối đến Ollama tại địa chỉ "${currentSettings.ollamaBaseUrl}". Vui lòng kiểm tra lại xem Ollama đã được khởi động chưa hoặc chuyển sang chế độ On-Device trong Cài đặt.';
              headerIcon = Icons.cloud_off_rounded;
              iconColor = AppColors.error;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Icon & Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(headerIcon, color: iconColor, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: AppTypography.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(bottomSheetContext).pop();
                              _openSettings(context);
                            },
                            child: const Text('Mở Cài đặt'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () {
                              if (isOnDevice) {
                                if (isDownloading) {
                                  // Đang tải thì đóng modal để xem tiến độ dưới AppBar
                                  Navigator.of(bottomSheetContext).pop();
                                } else {
                                  // Bắt đầu tải và tự động đóng modal để tránh duplicate UI
                                  settingsCubit.startModelDownload();
                                  Navigator.of(bottomSheetContext).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: const [
                                          Icon(
                                            Icons.cloud_download_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Bắt đầu tải mô hình On-Device. Theo dõi tiến trình ở đầu trang.',
                                            ),
                                          ),
                                        ],
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } else {
                                settingsCubit.testConnection();
                                Navigator.of(bottomSheetContext).pop();
                              }
                            },
                            child: Text(
                              isOnDevice
                                  ? (isDownloading
                                      ? 'Đóng xem tiến độ'
                                      : (hasPart
                                          ? 'Tiếp tục tải'
                                          : 'Tải mô hình ngay'))
                                  : 'Thử kết nối lại',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openLiveModal(BuildContext context, SettingsState settings) {
    if (!_ensureLlmReady(context, settings)) return;

    final currentProfile = settings.currentLanguage;
    LiveVoiceCallModal.show(
      context,
      languageName: currentProfile.name,
      flagEmoji: currentProfile.flagEmoji,
      systemPrompt: currentProfile.defaultSystemPrompt,
      ttsLocale: currentProfile.ttsLocale,
      sttLocale: currentProfile.sttLocale,
      voiceGender: settings.voiceGender,
      speechRate: settings.speechRate,
    );
  }

  Widget _buildConnectionBanner(
    BuildContext context,
    SettingsState settings,
    SettingsCubit settingsCubit,
  ) {
    final isOnDevice = settings.isOnDevice;

    // 1. On-Device Mode Cases
    if (isOnDevice) {
      if (settings.isDownloadingModel) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đang tải mô hình On-Device Qwen 2.5...',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () =>
                        settingsCubit.pauseOrCancelModelDownload(),
                    child: const Text('Tạm dừng'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: settings.downloadProgress > 0
                      ? settings.downloadProgress
                      : null,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  color: AppColors.primary,
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                settings.downloadStatusText,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      }

      if (settings.hasPartialDownload && !settings.isModelDownloaded) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.warning.withValues(alpha: 0.15),
          child: Row(
            children: [
              const Icon(
                Icons.pause_circle_filled_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tải On-Device AI tạm dừng (${settings.partialDownloadedMb} MB). Bấm tiếp tục để sử dụng.',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => settingsCubit.startModelDownload(),
                child: const Text(
                  'Tiếp tục tải',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }

      if (!settings.isModelDownloaded) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          color: AppColors.error.withValues(alpha: 0.12),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chưa có mô hình On-Device (~350MB). Cần tải model để trò chuyện offline.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => settingsCubit.startModelDownload(),
                icon: const Icon(Icons.cloud_download_rounded, size: 14),
                label: const Text(
                  'Tải ngay',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    }

    // 2. Ollama Mode Cases
    if (!isOnDevice) {
      if (settings.connectionStatus == ConnectionStatus.failed) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.error.withValues(alpha: 0.15),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chưa kết nối Ollama (${settings.ollamaBaseUrl}). Hãy kiểm tra xem Ollama đã chạy chưa.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => settingsCubit.testConnection(),
                child: const Text('Thử lại'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _openSettings(context),
                child: const Text('Cài đặt'),
              ),
            ],
          ),
        );
      }

      if (settings.connectionStatus == ConnectionStatus.checking) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Đang kiểm tra kết nối AI...',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.watch<SettingsCubit>();
    final settings = settingsCubit.state;
    final currentProfile = settings.currentLanguage;
    final isLlmReady = settings.isLlmReady;

    return BlocConsumer<VoiceChatCubit, VoiceChatState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) {
          _scrollToBottom();
        }
        if (!state.isLiveMode &&
            state.isListening &&
            state.partialRecognizedText.isNotEmpty) {
          _textController.text = state.partialRecognizedText;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        }
        if (state.errorMessage != null && !state.isLiveMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<VoiceChatCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EchoLingua AI', style: AppTypography.heading3),
                    Text(
                      '${currentProfile.flagEmoji} ${currentProfile.name} Tutor',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 4,
                ),
                child: InkWell(
                  onTap: () => _openLiveModal(context, settings),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: isLlmReady
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade700,
                                Colors.grey.shade800,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isLlmReady
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLlmReady
                              ? Icons.graphic_eq_rounded
                              : Icons.warning_amber_rounded,
                          color: isLlmReady ? Colors.white : AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: state.autoPlayTts
                    ? 'Tắt tự động phát âm'
                    : 'Bật tự động phát âm',
                icon: Icon(
                  state.autoPlayTts
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  color: state.autoPlayTts
                      ? AppColors.secondary
                      : AppColors.darkTextMuted,
                ),
                onPressed: () => cubit.toggleAutoPlayTts(),
              ),
              IconButton(
                tooltip: 'Xóa hội thoại',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: state.messages.isEmpty
                    ? null
                    : () => cubit.clearChat(),
              ),
            ],
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                // Interactive LLM Connection Status Banner
                _buildConnectionBanner(context, settings, settingsCubit),

                // Chat Messages or Empty Welcome View
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildWelcomeHero(
                          context,
                          cubit,
                          settings,
                          currentProfile.defaultSystemPrompt,
                          currentProfile.ttsLocale,
                          currentProfile.sttLocale,
                          currentProfile.name,
                          currentProfile.flagEmoji,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final msg = state
                                .messages[state.messages.length - 1 - index];
                            return ChatMessageBubble(
                              message: msg,
                              isPlayingAudio: state.speakingMessageId == msg.id,
                              onPlayAudio: () {
                                if (state.speakingMessageId == msg.id) {
                                  cubit.stopAudio();
                                } else {
                                  cubit.playMessageAudio(
                                    msg,
                                    locale: currentProfile.ttsLocale,
                                    voiceGender: settings.voiceGender,
                                    rate: settings.speechRate,
                                  );
                                }
                              },
                              onTranslate: () {
                                cubit.translateMessage(
                                  msg.id,
                                  targetLang: 'Vietnamese',
                                );
                              },
                            );
                          },
                        ),
                ),

                // Thinking Indicator
                if (state.isThinking)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(context).cardColor.withValues(alpha: 0.6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI đang suy nghĩ...',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Messenger-Style Bottom Input & Mic Control Bar
                _buildBottomControls(
                  context,
                  cubit,
                  state,
                  settings,
                  currentProfile.defaultSystemPrompt,
                  currentProfile.ttsLocale,
                  currentProfile.sttLocale,
                  settings.voiceGender,
                  settings.speechRate,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHero(
    BuildContext context,
    VoiceChatCubit cubit,
    SettingsState settings,
    String systemPrompt,
    String ttsLocale,
    String sttLocale,
    String languageName,
    String flagEmoji,
  ) {
    final isLlmReady = settings.isLlmReady;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Luyện Nói Trực Tiếp với Local AI',
              style: AppTypography.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Bấm nút Micro để nói, hoặc gõ văn bản.\nAI sẽ phản hồi bằng tiếng $languageName và phát âm chuẩn bản xứ.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _openLiveModal(context, settings),
              icon: Icon(
                isLlmReady
                    ? Icons.graphic_eq_rounded
                    : Icons.cloud_download_rounded,
                size: 20,
              ),
              label: Text(
                isLlmReady
                    ? 'Bắt đầu Trò chuyện Live Voice'
                    : (settings.isOnDevice
                        ? (settings.isDownloadingModel
                            ? 'Đang tải model (${(settings.downloadProgress * 100).toInt()}%)...'
                            : 'Tải Model AI để Bắt đầu Live')
                        : 'Kết nối Ollama để Bắt đầu Live'),
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isLlmReady ? AppColors.primary : AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildPromptChip(
                  '💬 Can you introduce yourself?',
                  context,
                  cubit,
                  settings,
                  systemPrompt,
                  ttsLocale,
                ),
                _buildPromptChip(
                  '☕ Order coffee at Starbucks',
                  context,
                  cubit,
                  settings,
                  systemPrompt,
                  ttsLocale,
                ),
                _buildPromptChip(
                  '💼 Job interview practice',
                  context,
                  cubit,
                  settings,
                  systemPrompt,
                  ttsLocale,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(
    String label,
    BuildContext context,
    VoiceChatCubit cubit,
    SettingsState settings,
    String systemPrompt,
    String ttsLocale,
  ) {
    return ActionChip(
      label: Text(label, style: AppTypography.bodySmall),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        if (!_ensureLlmReady(context, settings)) return;
        cubit.sendMessage(
          content: label.replaceFirst(RegExp(r'^[^\s]+\s'), ''),
          systemPrompt: systemPrompt,
          ttsLocale: ttsLocale,
        );
      },
    );
  }

  Widget _buildQuickPromptChips(
    BuildContext context,
    VoiceChatCubit cubit,
    SettingsState settings,
    String systemPrompt,
    String ttsLocale,
  ) {
    final prompts = [
      '👋 Giới thiệu bản thân',
      '☕ Order coffee at Starbucks',
      '💼 Job interview practice',
      '✈️ Airport check-in guide',
      '💡 Correct my grammar',
      '🎯 Daily conversation quiz',
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return ActionChip(
            label: Text(
              prompt,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: () {
              if (!_ensureLlmReady(context, settings)) return;
              final content = prompt.replaceFirst(RegExp(r'^[^\s]+\s'), '');
              cubit.sendMessage(
                content: content,
                systemPrompt: systemPrompt,
                ttsLocale: ttsLocale,
              );
              _scrollToBottom();
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    VoiceChatCubit cubit,
    VoiceChatState state,
    SettingsState settings,
    String systemPrompt,
    String ttsLocale,
    String sttLocale,
    String voiceGender,
    double speechRate,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showPromptChips)
          _buildQuickPromptChips(
            context,
            cubit,
            settings,
            systemPrompt,
            ttsLocale,
          ),
        MessengerInputBar(
          controller: _textController,
          focusNode: _focusNode,
          isListening: state.isListening,
          isThinking: state.isThinking,
          soundLevel: state.soundLevel,
          partialRecognizedText: state.partialRecognizedText,
          arePromptChipsVisible: _showPromptChips,
          onTogglePromptChips: () {
            setState(() {
              _showPromptChips = !_showPromptChips;
            });
          },
          onStartListening: () {
            if (!_ensureLlmReady(context, settings)) return;
            _textController.clear();
            cubit.startListening(locale: sttLocale);
          },
          onStopListeningAndSend: () {
            if (!_ensureLlmReady(context, settings)) return;
            _textController.clear();
            cubit.stopListeningAndSend(
              systemPrompt: systemPrompt,
              ttsLocale: ttsLocale,
              voiceGender: voiceGender,
              speechRate: speechRate,
            );
            _scrollToBottom();
          },
          onStopListeningOnly: () async {
            final recognized = await cubit.stopListeningOnly();
            if (recognized.isNotEmpty) {
              _textController.text = recognized;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: recognized.length),
              );
            }
            _focusNode.requestFocus();
          },
          onCancelListening: () {
            cubit.cancelListening();
            _textController.clear();
          },
          onSendMessage: (text) {
            if (!_ensureLlmReady(context, settings)) return;
            cubit.sendMessage(
              content: text,
              systemPrompt: systemPrompt,
              ttsLocale: ttsLocale,
              voiceGender: voiceGender,
              speechRate: speechRate,
            );
            _scrollToBottom();
          },
          onTapInput: () {
            if (_scrollController.hasClients && _scrollController.offset > 0) {
              _scrollToBottom();
            }
          },
        ),
      ],
    );
  }
}
