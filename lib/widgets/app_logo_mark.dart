import 'package:flutter/material.dart';

import '../app_theme.dart';

class AppLogoMark extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry padding;
  final bool showBackground;

  const AppLogoMark({
    super.key,
    this.size = 72,
    this.padding = const EdgeInsets.all(8),
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Padding(
      padding: padding,
      child: Image.asset(
        'assets/foodcal_logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );

    if (!showBackground) {
      return SizedBox(width: size, height: size, child: logo);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
      ),
      child: logo,
    );
  }
}
