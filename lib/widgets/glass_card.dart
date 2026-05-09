import 'dart:ui';

import 'package:flutter/material.dart';
import '../app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final LinearGradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.borderColor,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.cardRadius;
    final int alpha = (opacity * 255).toInt().clamp(0, 255);
    final int heavyAlpha = (opacity * 1.6 * 255).toInt().clamp(0, 255);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ?? AppTheme.softShadow(AppTheme.primaryColor),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? Color.fromARGB(alpha, 255, 255, 255) : null,
              gradient: gradient ??
                  LinearGradient(
                    colors: [
                      Color.fromARGB(heavyAlpha, 255, 255, 255),
                      Color.fromARGB(alpha, 255, 255, 255),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: radius,
              border: Border.all(
                color: borderColor ?? const Color(0x3DFFFFFF),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
