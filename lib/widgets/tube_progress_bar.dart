import 'package:flutter/material.dart';

class TubeProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> colors;
  final Color backgroundColor;
  final double height;
  final double borderRadius;
  final Duration duration;

  const TubeProgressBar({
    Key? key,
    required this.progress,
    required this.colors,
    this.backgroundColor = const Color(0xFFE3F2FD),
    this.height = 12.0,
    this.borderRadius = 12.0,
    this.duration = const Duration(milliseconds: 650),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: safeProgress),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Stack(
          children: [
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
