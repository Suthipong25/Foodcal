import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';

/// Keys stored in SharedPreferences
const _kShowWaterReminder = 'reminder_water';
const _kShowFoodReminder = 'reminder_food';
const _kShowWeightReminder = 'reminder_weight';

class ReminderService {
  static Future<Map<String, bool>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'water': prefs.getBool(_kShowWaterReminder) ?? true,
      'food': prefs.getBool(_kShowFoodReminder) ?? true,
      'weight': prefs.getBool(_kShowWeightReminder) ?? true,
    };
  }

  static Future<void> setSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (key) {
      case 'water':
        await prefs.setBool(_kShowWaterReminder, value);
        break;
      case 'food':
        await prefs.setBool(_kShowFoodReminder, value);
        break;
      case 'weight':
        await prefs.setBool(_kShowWeightReminder, value);
        break;
    }
  }
}

/// A dismissible in-app reminder banner shown at the top of a screen.
class ReminderBanner extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;

  const ReminderBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  State<ReminderBanner> createState() => _ReminderBannerState();
}

class _ReminderBannerState extends State<ReminderBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.10),
          borderRadius: AppTheme.cardRadius,
          border: Border.all(color: widget.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.message,
                style: TextStyle(
                  fontSize: AppTheme.body,
                  color: widget.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _dismissed = true),
              child: Icon(LucideIcons.x, size: 16, color: widget.color.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Evaluates which reminders should appear based on today's log data and
/// user preferences, then renders a column of [ReminderBanner]s.
class DailyReminderColumn extends StatefulWidget {
  final int waterGlasses;
  final int targetWater;
  final bool hasFoodToday;
  final bool hasWeightToday;

  const DailyReminderColumn({
    super.key,
    required this.waterGlasses,
    required this.targetWater,
    required this.hasFoodToday,
    required this.hasWeightToday,
  });

  @override
  State<DailyReminderColumn> createState() => _DailyReminderColumnState();
}

class _DailyReminderColumnState extends State<DailyReminderColumn> {
  Map<String, bool> _settings = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    ReminderService.getSettings().then((s) {
      if (mounted) setState(() { _settings = s; _loaded = true; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final banners = <Widget>[];

    if (_settings['food'] == true && !widget.hasFoodToday) {
      banners.add(const ReminderBanner(
        key: ValueKey('food_reminder'),
        message: '🍽️ ยังไม่ได้บันทึกอาหารวันนี้ กด "บันทึก" เพื่อเริ่ม',
        icon: LucideIcons.utensils,
        color: AppTheme.primaryColor,
      ));
    }

    if (_settings['water'] == true && widget.waterGlasses < widget.targetWater) {
      banners.add(ReminderBanner(
        key: const ValueKey('water_reminder'),
        message: '💧 ดื่มน้ำได้แค่ ${widget.waterGlasses}/${widget.targetWater} แก้ว — อย่าลืมดื่มน้ำ!',
        icon: LucideIcons.droplet,
        color: AppTheme.waterColor,
      ));
    }

    if (_settings['weight'] == true && !widget.hasWeightToday) {
      banners.add(const ReminderBanner(
        key: ValueKey('weight_reminder'),
        message: '⚖️ ยังไม่ได้ชั่งน้ำหนักวันนี้ บันทึกเพื่อดู trend',
        icon: LucideIcons.scale,
        color: AppTheme.success,
      ));
    }

    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(children: banners);
  }
}
