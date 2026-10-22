import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';
import 'package:echo_lingua/core/theme/app_typography.dart';
import 'package:echo_lingua/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:echo_lingua/features/settings/presentation/cubit/settings_state.dart';
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

  void _scrollToBottom({int delayMs = 0}) {
    void doScroll() {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final currentProfile = settings.currentLanguage;

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
        if (state.errorMessage != null) {
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
                  onTap: () {
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
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white,
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
                // Connection status notice if failed
                if (settings.connectionStatus == ConnectionStatus.failed)
                  Container(
                    width: double.infinity,
                    color: AppColors.error.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chưa kết nối Local LLM. Kiểm tra Ollama tại mục Cài đặt.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Chat Messages or Empty Welcome View
                Expanded(
                  child: state.messages.isEmpty
                      ? _buildWelcomeHero(
                          context,
                          cubit,
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
                            // Reverse indexing: index 0 is at bottom (latest message)
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
    String systemPrompt,
    String ttsLocale,
    String sttLocale,
    String languageName,
    String flagEmoji,
  ) {
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
              'Bấm nút Micro để nói, hoặc gõ văn bản.\nAI sẽ phản hồi bằng tiếng Anh và phát âm chuẩn bản xứ.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                final settings = context.read<SettingsCubit>().state;
                LiveVoiceCallModal.show(
                  context,
                  languageName: languageName,
                  flagEmoji: flagEmoji,
                  systemPrompt: systemPrompt,
                  ttsLocale: ttsLocale,
                  sttLocale: sttLocale,
                  voiceGender: settings.voiceGender,
                  speechRate: settings.speechRate,
                );
              },
              icon: const Icon(Icons.graphic_eq_rounded, size: 20),
              label: Text(
                'Bắt đầu Trò chuyện Live Voice',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
                  cubit,
                  systemPrompt,
                  ttsLocale,
                ),
                _buildPromptChip(
                  '☕ Order coffee at Starbucks',
                  cubit,
                  systemPrompt,
                  ttsLocale,
                ),
                _buildPromptChip(
                  '💼 Job interview practice',
                  cubit,
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
    VoiceChatCubit cubit,
    String systemPrompt,
    String ttsLocale,
  ) {
    return ActionChip(
      label: Text(label, style: AppTypography.bodySmall),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        cubit.sendMessage(
          content: label.replaceFirst(RegExp(r'^[^\s]+\s'), ''),
          systemPrompt: systemPrompt,
          ttsLocale: ttsLocale,
        );
      },
    );
  }

  Widget _buildQuickPromptChips(
    VoiceChatCubit cubit,
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
          _buildQuickPromptChips(cubit, systemPrompt, ttsLocale),
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
            _textController.clear();
            cubit.startListening(locale: sttLocale);
          },
          onStopListeningAndSend: () {
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
