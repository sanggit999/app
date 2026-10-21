import 'package:flutter/material.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';

class PulsingMicButton extends StatefulWidget {
  final bool isListening;
  final double soundLevel;
  final VoidCallback onPressed;
  final double size;

  const PulsingMicButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.soundLevel = 0.0,
    this.size = 72.0,
  });

  @override
  State<PulsingMicButton> createState() => _PulsingMicButtonState();
}

class _PulsingMicButtonState extends State<PulsingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.isListening) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(PulsingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat();
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic scale based on mic sound level
    final double levelFactor = (widget.soundLevel / 10.0).clamp(0.0, 1.0);
    final double scale = 1.0 + (levelFactor * 0.15);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring 2
            if (widget.isListening)
              Container(
                width: widget.size * (1.3 + _pulseController.value * 0.5),
                height: widget.size * (1.3 + _pulseController.value * 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withValues(
                    alpha: (1.0 - _pulseController.value) * 0.2,
                  ),
                ),
              ),

            // Outer pulse ring 1
            if (widget.isListening)
              Container(
                width: widget.size * (1.1 + _pulseController.value * 0.3),
                height: widget.size * (1.1 + _pulseController.value * 0.3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(
                    alpha: (1.0 - _pulseController.value) * 0.35,
                  ),
                ),
              ),

            // Core button
            Transform.scale(
              scale: widget.isListening ? scale : 1.0,
              child: GestureDetector(
                onTap: widget.onPressed,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isListening
                          ? [AppColors.micRecording, const Color(0xFFDC2626)]
                          : [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isListening
                                ? AppColors.micRecording
                                : AppColors.primary)
                            .withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: widget.size * 0.48,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
