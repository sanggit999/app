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

  const LiveVoiceCallModal({
    super.key,
    required this.languageName,
    required this.flagEmoji,
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
    cubit.startLiveMode(
      systemPrompt: systemPrompt,
      ttsLocale: ttsLocale,
      sttLocale: sttLocale,
      voiceGender: voiceGender,
      speechRate: speechRate,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      isDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: LiveVoiceCallModal(
          languageName: languageName,
          flagEmoji: flagEmoji,
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

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _auraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoiceChatCubit, VoiceChatState>(
      listener: (context, state) {
        if (!state.isLiveMode) {
          Navigator.of(context).maybePop();
        }
      },
      builder: (context, state) {
        final cubit = context.read<VoiceChatCubit>();
        final status = state.liveStatus;

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop && cubit.state.isLiveMode) {
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
                          onPressed: () => cubit.stopLiveMode(),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Center Dynamic Ambient Aura Orb
                  _buildAuraOrb(state, status, cubit),

                  const SizedBox(height: 36),

                  // Live Status Label
                  _buildStatusLabel(status),

                  const SizedBox(height: 16),

                  // Live Transcription / AI Speech Text Box
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 64,
                        maxHeight: 110,
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
                          child: Text(
                            _getDisplayText(state, status),
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
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
                          color: status == 'speaking'
                              ? AppColors.secondary
                              : Colors.white60,
                          onTap: () => cubit.bargeIn(),
                        ),

                        // End Call Button
                        GestureDetector(
                          onTap: () => cubit.stopLiveMode(),
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
            if (status == 'speaking') {
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
                            : AudioWaveVisualizer(
                                isActive: state.isListening,
                                soundLevel: state.soundLevel,
                                height: 32,
                                color: Colors.white,
                              )),
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
    } else {
      text = '🎙️ Đang lắng nghe... hãy nói ${widget.languageName}';
      color = AppColors.secondary;
    }

    return Text(
      text,
      style: AppTypography.heading3.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
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
