import 'package:flutter/material.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';

class AudioPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;
  final Color? activeColor;

  const AudioPlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 36.0,
    this.activeColor,
  });

  @override
  State<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    if (widget.isPlaying) {
      _waveController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AudioPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _waveController.repeat(reverse: true);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _waveController.stop();
      _waveController.reset();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCol = widget.activeColor ?? AppColors.secondary;

    return InkWell(
      onTap: widget.onPressed,
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isPlaying
              ? activeCol.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.04),
          border: Border.all(
            color: widget.isPlaying ? activeCol : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Center(
          child: widget.isPlaying
              ? AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return Icon(
                      Icons.volume_up_rounded,
                      color: activeCol,
                      size: widget.size * (0.55 + _waveController.value * 0.1),
                    );
                  },
                )
              : Icon(
                  Icons.volume_up_outlined,
                  color: AppColors.darkTextSecondary,
                  size: widget.size * 0.55,
                ),
        ),
      ),
    );
  }
}
