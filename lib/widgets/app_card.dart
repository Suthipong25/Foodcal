import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'glass_card.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      opacity: backgroundColor == null ? 0.14 : 0.18,
      borderRadius: borderRadius,
      borderColor: borderColor ?? AppTheme.cardBorder,
      boxShadow: boxShadow,
      gradient: backgroundColor == null
          ? null
          : LinearGradient(
              colors: [
                backgroundColor!,
                backgroundColor!.withValues(alpha: 0.74),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      child: child,
    );
  }
}
