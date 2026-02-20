import 'package:flutter/material.dart';

class TubeProgressBar extends StatelessWidget {
  final double progress;
  final List<Color> colors;
  final Color backgroundColor;
  final double height;
  final double borderRadius;

  const TubeProgressBar({
    Key? key,
    required this.progress,
    required this.colors,
    this.backgroundColor = const Color(0xFFE3F2FD), // Colors.blue[50]
    this.height = 12.0,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          widthFactor: progress.clamp(0.0, 1.0),
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
  }
}
