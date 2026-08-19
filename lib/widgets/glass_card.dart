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
    this.opacity = 0.12,
    this.borderRadius,
    this.padding,
    this.borderColor,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.cardRadius;
    final resolvedBorderColor = borderColor ?? AppTheme.cardBorder;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ?? AppTheme.softShadow(AppTheme.ink),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur.clamp(0, 10).toDouble(),
            sigmaY: blur.clamp(0, 10).toDouble(),
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? AppTheme.surface : null,
              gradient: gradient ??
                  const LinearGradient(
                    colors: [
                      AppTheme.surface,
                      Color(0xFFF8FAFC),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: radius,
              border: Border.all(
                color: resolvedBorderColor,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
