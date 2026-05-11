import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'app_chip.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? accentColor;

  const AppSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppChip(label: title, color: accentColor),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: AppTheme.body,
            color: AppTheme.mutedText,
          ),
        ),
      ],
    );
  }
}
