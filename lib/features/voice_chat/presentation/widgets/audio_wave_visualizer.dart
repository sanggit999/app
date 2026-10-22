import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:echo_lingua/core/theme/app_colors.dart';

class AudioWaveVisualizer extends StatefulWidget {
  final bool isActive;
  final double soundLevel;
  final int barCount;
  final double height;
  final Color? color;

  const AudioWaveVisualizer({
    super.key,
    required this.isActive,
    this.soundLevel = 0.0,
    this.barCount = 18,
    this.height = 36.0,
    this.color,
  });

  @override
  State<AudioWaveVisualizer> createState() => _AudioWaveVisualizerState();
}

class _AudioWaveVisualizerState extends State<AudioWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.color ?? AppColors.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth =
            constraints.hasBoundedWidth && constraints.maxWidth > 0
            ? constraints.maxWidth
            : widget.barCount * 7.5;
        final int effectiveBars = math.max(
          4,
          (availableWidth / 7.5).floor().clamp(4, widget.barCount),
        );

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            return SizedBox(
              height: widget.height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(effectiveBars, (index) {
                  final double normalizedIndex = index / effectiveBars;
                  final double phase = _animController.value * 2 * math.pi;

                  double barHeight;
                  if (widget.isActive) {
                    final double soundBoost = (widget.soundLevel / 10.0).clamp(
                      0.0,
                      1.0,
                    );
                    final double wave =
                        (math.sin(phase + normalizedIndex * 4 * math.pi) + 1) /
                        2;
                    barHeight =
                        6.0 +
                        (wave * 0.6 + soundBoost * 0.4) * (widget.height - 6.0);
                  } else {
                    barHeight = 4.0;
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    width: 3.5,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? waveColor.withValues(
                              alpha: (0.5 + 0.5 * (barHeight / widget.height))
                                  .clamp(0.0, 1.0),
                            )
                          : AppColors.darkTextMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}
