import 'package:flutter/material.dart';

class AppIconBubble extends StatelessWidget {
  final Color color;
  final Widget child;
  final double size;
  final double opacity;

  const AppIconBubble({
    super.key,
    required this.color,
    required this.child,
    this.size = 36,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
