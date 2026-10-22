import 'package:flutter/material.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';
import 'package:echo_lingua/core/theme/app_typography.dart';
import 'audio_wave_visualizer.dart';

class MessengerInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final bool isThinking;
  final double soundLevel;
  final String partialRecognizedText;
  final VoidCallback onStartListening;
  final VoidCallback onStopListeningAndSend;
  final VoidCallback onCancelListening;
  final VoidCallback? onStopListeningOnly;
  final ValueChanged<String> onSendMessage;
  final VoidCallback? onTapInput;
  final VoidCallback? onTogglePromptChips;
  final bool arePromptChipsVisible;

  const MessengerInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.isThinking,
    required this.soundLevel,
    required this.partialRecognizedText,
    required this.onStartListening,
    required this.onStopListeningAndSend,
    required this.onCancelListening,
    this.onStopListeningOnly,
    required this.onSendMessage,
    this.onTapInput,
    this.onTogglePromptChips,
    this.arePromptChipsVisible = false,
  });

  @override
  State<MessengerInputBar> createState() => _MessengerInputBarState();
}

class _MessengerInputBarState extends State<MessengerInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTextChanged() {
    final hasContent = widget.controller.text.trim().isNotEmpty;
    if (hasContent != _hasText) {
      setState(() {
        _hasText = hasContent;
      });
    }
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.controller.clear();
      widget.onSendMessage(text);
      setState(() => _hasText = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? AppColors.inputFillDark : AppColors.inputFillLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: widget.isListening
              ? _buildRecordingBar(context, isDark)
              : _buildStandardInputBar(context, isDark, pillBg),
        ),
      ),
    );
  }

  Widget _buildStandardInputBar(BuildContext context, bool isDark, Color pillBg) {
    return Row(
      key: const ValueKey('standard_input_bar'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Quick Action / Prompt Chips Toggle Button
        IconButton(
          tooltip: 'Gợi ý chủ đề',
          icon: Icon(
            widget.arePromptChipsVisible
                ? Icons.lightbulb_rounded
                : Icons.lightbulb_outline_rounded,
            color: widget.arePromptChipsVisible
                ? AppColors.accent
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          onPressed: widget.onTogglePromptChips,
        ),

        // Rounded Pill Input Field
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.focusNode.hasFocus
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                width: widget.focusNode.hasFocus ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    onTap: widget.onTapInput,
                    onSubmitted: (_) => _submit(),
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Nhắn tin bằng tiếng Anh...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
                    ),
                  ),
                ),
                if (_hasText)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0, bottom: 2.0),
                    child: IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Xóa chữ',
                      icon: Icon(
                        Icons.cancel_rounded,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() => _hasText = false);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Dynamic Action Button (Mic ↔ Send)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: _hasText
              ? _buildSendButton()
              : _buildMicButton(isDark),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Container(
      key: const ValueKey('send_button'),
      width: 44,
      height: 44,
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
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
        tooltip: 'Gửi tin nhắn',
        onPressed: _submit,
      ),
    );
  }

  Widget _buildMicButton(bool isDark) {
    return Container(
      key: const ValueKey('mic_button'),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
      ),
      child: IconButton(
        icon: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 24),
        tooltip: 'Nói tiếng Anh',
        onPressed: widget.onStartListening,
      ),
    );
  }

  Widget _buildRecordingBar(BuildContext context, bool isDark) {
    return Container(
      key: const ValueKey('recording_bar'),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        children: [
          // Cancel recording button
          IconButton(
            tooltip: 'Hủy ghi âm',
            icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 24),
            onPressed: widget.onCancelListening,
          ),

          const SizedBox(width: 4),

          // Audio visualizer and live transcription
          Expanded(
            child: GestureDetector(
              onTap: widget.onStopListeningAndSend,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: widget.partialRecognizedText.isEmpty
                          ? AudioWaveVisualizer(
                              isActive: true,
                              soundLevel: widget.soundLevel,
                              height: 20,
                            )
                          : Text(
                              widget.partialRecognizedText,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (widget.onStopListeningOnly != null && widget.partialRecognizedText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: IconButton(
                tooltip: 'Giữ chữ để sửa',
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.secondary, size: 26),
                onPressed: widget.onStopListeningOnly,
              ),
            ),

          // Stop and Send voice button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
              tooltip: 'Xong & Gửi',
              onPressed: widget.onStopListeningAndSend,
            ),
          ),
        ],
      ),
    );
  }
}
