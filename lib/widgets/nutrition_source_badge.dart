import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/nutrition_result.dart';

/// Badge แสดงแหล่งที่มาของข้อมูลโภชนาการ
class NutritionSourceBadge extends StatelessWidget {
  final NutritionSource source;
  final String? servingLabel;

  const NutritionSourceBadge({
    super.key,
    required this.source,
    this.servingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (source) {
      NutritionSource.database => (
          const Color(0xFF16A34A), // green-600
          LucideIcons.database,
          'ฐานข้อมูล',
        ),
      NutritionSource.aiEstimate => (
          const Color(0xFFD97706), // amber-600
          LucideIcons.sparkles,
          'ค่าประมาณ AI',
        ),
      NutritionSource.manual => (
          const Color(0xFF2563EB), // blue-600
          LucideIcons.pencil,
          'กรอกเอง',
        ),
    };

    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        if (servingLabel != null && servingLabel!.isNotEmpty)
          Text(
            servingLabel!,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
      ],
    );
  }
}
