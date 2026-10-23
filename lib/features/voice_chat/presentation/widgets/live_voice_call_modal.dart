import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';
import 'package:echo_lingua/core/theme/app_typography.dart';
import 'package:echo_lingua/features/voice_chat/presentation/cubit/voice_chat_cubit.dart';
import 'package:echo_lingua/features/voice_chat/presentation/cubit/voice_chat_state.dart';

import 'audio_wave_visualizer.dart';

class LiveVoiceCallModal extends StatefulWidget {
  final String languageName;
  final String flagEmoji;
  final String systemPrompt;
  final String ttsLocale;
  final String sttLocale;
  final String voiceGender;
  final double speechRate;

  const LiveVoiceCallModal({
    super.key,
    required this.languageName,
    required this.flagEmoji,
    required this.systemPrompt,
    required this.ttsLocale,
    required this.sttLocale,
    this.voiceGender = 'female',
    this.speechRate = 0.5,
  });

  static Future<void> show(
    BuildContext context, {
    required String languageName,
    required String flagEmoji,
    required String systemPrompt,
    required String ttsLocale,
    required String sttLocale,
    String voiceGender = 'female',
    double speechRate = 0.5,
  }) async {
    final cubit = context.read<VoiceChatCubit>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: LiveVoiceCallModal(
          languageName: languageName,
          flagEmoji: flagEmoji,
          systemPrompt: systemPrompt,
          ttsLocale: ttsLocale,
          sttLocale: sttLocale,
          voiceGender: voiceGender,
          speechRate: speechRate,
        ),
      ),
    );

    if (cubit.state.isLiveMode) {
      await cubit.stopLiveMode();
    }
  }

  @override
  State<LiveVoiceCallModal> createState() => _LiveVoiceCallModalState();
}

class _LiveVoiceCallModalState extends State<LiveVoiceCallModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _auraController;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Safely trigger live mode after bottom sheet has mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isExiting) {
        final cubit = context.read<VoiceChatCubit>();
        cubit.startLiveMode(
          systemPrompt: widget.systemPrompt,
          ttsLocale: widget.ttsLocale,
          sttLocale: widget.sttLocale,
          voiceGender: widget.voiceGender,
          speechRate: widget.speechRate,
        );
      }
    });
  }

  @override
  void dispose() {
    _auraController.dispose();
    super.dispose();
  }

  void _safeClose() {
    if (_isExiting) return;
    _isExiting = true;
    final cubit = context.read<VoiceChatCubit>();
    if (cubit.state.isLiveMode) {
      cubit.stopLiveMode();
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoiceChatCubit, VoiceChatState>(
      listener: (context, state) {
        if (!state.isLiveMode && !_isExiting) {
          _isExiting = true;
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      builder: (context, state) {
        final cubit = context.read<VoiceChatCubit>();
        final status = state.liveStatus;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            _isExiting = true;
            if (cubit.state.isLiveMode) {
              cubit.stopLiveMode();
            }
          },
          child: Container(
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.flagEmoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.languageName} Live Tutor',
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 26,
                          ),
                          onPressed: _safeClose,
                        ),
                      ],
                    ),
                  ),

                  // Optional Error Banner in Live Mode
                  if (state.errorMessage != null &&
                      state.errorMessage!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => cubit.bargeIn(),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Center Dynamic Ambient Aura Orb
                  _buildAuraOrb(state, status, cubit),

                  const SizedBox(height: 32),

                  // Live Status Label
                  _buildStatusLabel(status),

                  const SizedBox(height: 16),

                  // Live Transcription / AI Speech Text Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 64,
                        maxHeight: 120,
                      ),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            _getDisplayText(state, status),
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontStyle: status == 'thinking'
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Control Action Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Barge-in / Speak Now Button
                        _buildSecondaryAction(
                          icon: Icons.mic_rounded,
                          label: 'Nói ngay',
                          color: (status == 'speaking' || status == 'idle')
                              ? AppColors.secondary
                              : Colors.white60,
                          onTap: () => cubit.bargeIn(),
                        ),

                        // End Call Button
                        GestureDetector(
                          onTap: _safeClose,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.error,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),

                        // Mute / Listen Toggle
                        _buildSecondaryAction(
                          icon: state.isListening
                              ? Icons.hearing_rounded
                              : Icons.hearing_disabled_rounded,
                          label: state.isListening ? 'Đang nghe' : 'Tạm dừng',
                          color: state.isListening
                              ? AppColors.success
                              : Colors.white60,
                          onTap: () {
                            if (state.isListening) {
                              cubit.cancelListening();
                            } else {
                              cubit.bargeIn();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuraOrb(
    VoiceChatState state,
    String status,
    VoiceChatCubit cubit,
  ) {
    Color orbColor;
    Color glowColor;

    if (status == 'speaking') {
      orbColor = AppColors.success;
      glowColor = AppColors.success.withValues(alpha: 0.35);
    } else if (status == 'thinking') {
      orbColor = AppColors.primaryLight;
      glowColor = AppColors.primary.withValues(alpha: 0.4);
    } else if (status == 'idle') {
      orbColor = Colors.grey.shade600;
      glowColor = Colors.grey.withValues(alpha: 0.25);
    } else {
      orbColor = AppColors.secondary;
      glowColor = AppColors.secondary.withValues(alpha: 0.4);
    }

    final double levelFactor = (state.soundLevel / 10.0).clamp(0.0, 1.0);
    final double voiceScale = 1.0 + (levelFactor * 0.25);

    return AnimatedBuilder(
      animation: _auraController,
      builder: (context, _) {
        final double pulse = _auraController.value;

        return GestureDetector(
          onTap: () {
            if (status == 'speaking' || status == 'idle') {
              cubit.bargeIn();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Expanding Glow
              Container(
                width: 190 * (1.0 + pulse * 0.15) * voiceScale,
                height: 190 * (1.0 + pulse * 0.15) * voiceScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor.withValues(alpha: (1.0 - pulse) * 0.25),
                ),
              ),

              // Middle Soft Ring
              Container(
                width: 155 * (1.0 + pulse * 0.08),
                height: 155 * (1.0 + pulse * 0.08),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: glowColor,
                ),
              ),

              // Core Solid Orb
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [orbColor, orbColor.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: orbColor.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: status == 'thinking'
                      ? const SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: Colors.white,
                          ),
                        )
                      : (status == 'speaking'
                            ? const Icon(
                                Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 52,
                              )
                            : (status == 'idle'
                                  ? const Icon(
                                      Icons.touch_app_rounded,
                                      color: Colors.white,
                                      size: 44,
                                    )
                                  : AudioWaveVisualizer(
                                      isActive: state.isListening,
                                      soundLevel: state.soundLevel,
                                      height: 32,
                                      color: Colors.white,
                                    ))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusLabel(String status) {
    String text;
    Color color;

    if (status == 'speaking') {
      text = '🔊 AI đang nói chuyện với bạn...';
      color = AppColors.success;
    } else if (status == 'thinking') {
      text = '✨ Gia sư AI đang suy nghĩ...';
      color = AppColors.primaryLight;
    } else if (status == 'idle') {
      text = '⏸️ Đang tạm dừng. Chạm Orb hoặc bấm "Nói ngay"';
      color = Colors.white70;
    } else {
      text = '🎙️ Đang lắng nghe... hãy nói ${widget.languageName}';
      color = AppColors.secondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        style: AppTypography.heading3.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getDisplayText(VoiceChatState state, String status) {
    if (status == 'thinking') {
      return state.partialRecognizedText.isNotEmpty
          ? '"${state.partialRecognizedText}"'
          : 'Đang kết nối suy nghĩ...';
    }
    if (status == 'speaking' && state.messages.isNotEmpty) {
      final lastAi = state.messages.lastWhere(
        (m) => !m.isUser,
        orElse: () => state.messages.last,
      );
      return lastAi.content.isNotEmpty ? lastAi.content : '...';
    }
    if (state.partialRecognizedText.isNotEmpty) {
      return '"${state.partialRecognizedText}"';
    }
    if (status == 'idle') {
      return 'Bấm "Nói ngay" để tiếp tục cuộc trò chuyện.';
    }
    return 'Hãy nói tự nhiên, gia sư AI sẽ nghe và phản hồi trực tiếp bằng giọng nói.';
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
