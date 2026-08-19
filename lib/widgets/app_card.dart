import 'package:flutter/material.dart';

import '../app_theme.dart';

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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? AppTheme.cardRadius,
        border: Border.all(color: borderColor ?? const Color(0xFFE5F0DE)),
        boxShadow: boxShadow ?? AppTheme.softShadow(AppTheme.primaryColor),
      ),
      child: child,
    );
  }
}
