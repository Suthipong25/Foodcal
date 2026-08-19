import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'app_card.dart';
import 'app_icon_bubble.dart';

class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final EdgeInsetsGeometry? padding;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderRadius: AppTheme.innerRadius,
      borderColor: AppTheme.cardBorder,
      boxShadow: AppTheme.softShadow(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconBubble(
            color: color,
            size: 34,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTheme.meta,
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTheme.body,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
