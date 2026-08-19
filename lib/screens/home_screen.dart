import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/datetime_utils.dart';
import '../widgets/reminder_banner.dart';
import '../widgets/tube_progress_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/app_section_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/organic_page.dart';
import 'ai_coach_screen.dart';

class TipItem {
  final String text;
  final IconData icon;
  final Color color;

  const TipItem(this.text, this.icon, this.color);
}

const List<TipItem> _tips = [
  TipItem(
    'ดื่มน้ำก่อนอาหาร 30 นาที ช่วยลดความอยากอาหารได้',
    LucideIcons.droplet,
    AppTheme.waterColor,
  ),
  TipItem(
    'โปรตีนช่วยให้อิ่มนานและซ่อมแซมกล้ามเนื้อได้ดี',
    LucideIcons.beef,
    AppTheme.proteinColor,
  ),
  TipItem(
    'จดอาหารทุกวันช่วยให้คุมแคลอรี่ได้แม่นขึ้น',
    LucideIcons.bookOpen,
    AppTheme.primaryColor,
  ),
  TipItem(
    'นอนให้พอ 7-8 ชั่วโมง ช่วยคุมฮอร์โมนความหิว',
    LucideIcons.moon,
    AppTheme.fatColor,
  ),
];

class DashboardScreen extends StatelessWidget {
  final UserProfile profile;
  final DailyLog? log;
  final List<DailyLog> weeklyLogs;
  final Function(int) onSwitchTab;

  const DashboardScreen({
    super.key,
    required this.profile,
    required this.log,
    required this.weeklyLogs,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = AppTheme.isCompactWidth(screenWidth);
    final caloriesIn = log?.caloriesIn ?? 0;
    final targetCalories = profile.targetCalories;
    final remainingCalories = targetCalories - caloriesIn;
    final currentProtein = log?.protein ?? 0;
    final currentCarbs = log?.carbs ?? 0;
    final currentFat = log?.fat ?? 0;
    final currentWater = log?.waterGlasses ?? 0;
    final progress = targetCalories > 0
        ? (caloriesIn / targetCalories).clamp(0.0, 1.0)
        : 0.0;
    final todayTip = _tips[DateTimeUtils.now().day % _tips.length];

    final uid =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return OrganicPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<dynamic>>(
            stream: fs.streamWeightLogs(uid, limit: 1),
            builder: (context, snap) {
              final logs = snap.data ?? [];
              final hasWeight =
                  logs.isNotEmpty && logs.first.date == FirestoreService.dateKey();
              if (caloriesIn > 0 &&
                  currentWater >= profile.targetWaterGlasses &&
                  hasWeight) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DailyReminderColumn(
                  waterGlasses: currentWater,
                  targetWater: profile.targetWaterGlasses,
                  hasFoodToday: caloriesIn > 0,
                  hasWeightToday: hasWeight,
                ),
              );
            },
          ),
          OrganicHeroPanel(
            eyebrow: 'วันนี้ของคุณ',
            title: remainingCalories < 0
                ? 'ค่อย ๆ กลับมาสมดุลได้'
                : 'ยังมีพื้นที่ให้กินอย่างสบายใจ',
            subtitle: remainingCalories < 0
                ? 'เกินเป้าไป ${remainingCalories.abs()} kcal แล้ว ลองเลือกมื้อเบาและเติมน้ำให้พอในช่วงที่เหลือ'
                : 'เหลืออีก $remainingCalories kcal จากเป้าหมาย $targetCalories kcal วันนี้',
            icon: LucideIcons.heart,
            color: remainingCalories < 0 ? AppTheme.accentColor : AppTheme.primaryColor,
            trailing: _HeroRing(
              progress: progress,
              caloriesIn: caloriesIn,
              targetCalories: targetCalories,
              emphasis:
                  remainingCalories < 0 ? AppTheme.error : AppTheme.primaryColor,
              compact: true,
            ),
            footer: [
              OrganicPill(
                label: '${profile.streak} วันต่อเนื่อง',
                icon: LucideIcons.flame,
                color: AppTheme.warning,
              ),
              OrganicPill(
                label: '$currentWater/${profile.targetWaterGlasses} แก้ว',
                icon: LucideIcons.droplet,
                color: AppTheme.waterColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isCompact) ...[
            OrganicActionTile(
              icon: LucideIcons.plus,
              title: 'บันทึกอาหาร',
              subtitle: 'เพิ่มมื้อใหม่หรือสแกนด้วย AI',
              color: AppTheme.primaryColor,
              onTap: () => onSwitchTab(1),
            ),
            const SizedBox(height: 10),
            OrganicActionTile(
              icon: LucideIcons.play,
              title: 'ขยับร่างกาย',
              subtitle: 'เปิดบทความและวิดีโอสุขภาพ',
              color: AppTheme.warmOrange,
              onTap: () => onSwitchTab(2),
            ),
            const SizedBox(height: 10),
            OrganicActionTile(
              icon: LucideIcons.messageCircle,
              title: 'ถาม AI Coach',
              subtitle: 'ให้ช่วยคิดเมนูหรือปรับแผนวันนี้',
              color: AppTheme.aiColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AICoachScreen()),
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: OrganicActionTile(
                    icon: LucideIcons.plus,
                    title: 'บันทึกอาหาร',
                    subtitle: 'เพิ่มมื้อใหม่หรือสแกนด้วย AI',
                    color: AppTheme.primaryColor,
                    onTap: () => onSwitchTab(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OrganicActionTile(
                    icon: LucideIcons.play,
                    title: 'ขยับร่างกาย',
                    subtitle: 'เปิดบทความและวิดีโอสุขภาพ',
                    color: AppTheme.warmOrange,
                    onTap: () => onSwitchTab(2),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppTheme.sectionGap),
          const _SectionHeader(
            title: 'สวนสารอาหาร',
            subtitle: 'แถบแต่ละสีคือสิ่งที่ร่างกายได้รับวันนี้',
          ),
          const SizedBox(height: 12),
          _MacroGarden(
            protein: currentProtein,
            proteinTarget: profile.targetProtein,
            carbs: currentCarbs,
            carbsTarget: profile.targetCarbs,
            fat: currentFat,
            fatTarget: profile.targetFat,
          ),
          const SizedBox(height: AppTheme.sectionGap),
          if (isCompact) ...[
            _WaterCard(
              currentWater: currentWater,
              targetWater: profile.targetWaterGlasses,
            ),
            const SizedBox(height: 12),
            _TipCard(tip: todayTip),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _WaterCard(
                    currentWater: currentWater,
                    targetWater: profile.targetWaterGlasses,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _TipCard(tip: todayTip)),
              ],
            ),
          const SizedBox(height: AppTheme.sectionGap),
          _WeeklyChart(profile: profile, weeklyLogs: weeklyLogs),
        ],
      ),
    );
  }
}

class _HeroRing extends StatelessWidget {
  final double progress;
  final int caloriesIn;
  final int targetCalories;
  final Color emphasis;
  final bool compact;

  const _HeroRing({
    required this.progress,
    required this.caloriesIn,
    required this.targetCalories,
    required this.emphasis,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 132.0 : 144.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _CalorieRingPainter(
              progress: progress,
              isOver: emphasis == AppTheme.error,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.zap, color: emphasis, size: 22),
                const SizedBox(height: 6),
                Text(
                  '$caloriesIn',
                  style: TextStyle(
                    fontSize: compact ? 24 : 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  '/ $targetCalories kcal',
                  style: const TextStyle(
                    fontSize: AppTheme.meta,
                    color: AppTheme.mutedText,
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

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final bool isOver;

  const _CalorieRingPainter({
    required this.progress,
    required this.isOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 14.0;
    final rect = Offset.zero & size;
    final ringRect = rect.deflate(strokeWidth / 2);
    const startAngle = -math.pi / 2;
    final sweep = math.pi * 2 * progress.clamp(0.0, 1.0);

    final bgPaint = Paint()
      ..color = AppTheme.pageTintStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ringRect, 0, math.pi * 2, false, bgPaint);

    final progressPaint = Paint()
      ..shader = (isOver
              ? const LinearGradient(colors: [AppTheme.error, AppTheme.warning])
              : AppTheme.calorieRingGradient)
          .createShader(ringRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ringRect, startAngle, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isOver != isOver;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      subtitle: subtitle,
    );
  }
}

class _MacroGarden extends StatelessWidget {
  final int protein;
  final int proteinTarget;
  final int carbs;
  final int carbsTarget;
  final int fat;
  final int fatTarget;

  const _MacroGarden({
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      opacity: 0.14,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _MacroGardenRow(
            label: 'โปรตีน',
            value: protein,
            target: proteinTarget,
            icon: LucideIcons.beef,
            color: AppTheme.proteinColor,
          ),
          const SizedBox(height: 16),
          _MacroGardenRow(
            label: 'คาร์บ',
            value: carbs,
            target: carbsTarget,
            icon: LucideIcons.sun,
            color: AppTheme.carbsColor,
          ),
          const SizedBox(height: 16),
          _MacroGardenRow(
            label: 'ไขมัน',
            value: fat,
            target: fatTarget,
            icon: LucideIcons.moon,
            color: AppTheme.fatColor,
          ),
        ],
      ),
    );
  }
}

class _MacroGardenRow extends StatelessWidget {
  final String label;
  final int value;
  final int target;
  final IconData icon;
  final Color color;

  const _MacroGardenRow({
    required this.label,
    required this.value,
    required this.target,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - value;

    return Row(
      children: [
        AppIconBubble(
          color: color,
          size: 42,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '$value / $target g',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TubeProgressBar(
                progress: progress,
                colors: [color.withValues(alpha: 0.55), color],
                backgroundColor: color.withValues(alpha: 0.1),
                height: 10,
                borderRadius: 999,
              ),
              const SizedBox(height: 6),
              Text(
                remaining < 0
                    ? 'เกิน ${remaining.abs()} g'
                    : 'เหลือ $remaining g',
                style: TextStyle(
                  color: remaining < 0 ? AppTheme.error : AppTheme.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final UserProfile profile;
  final List<DailyLog> weeklyLogs;

  const _WeeklyChart({required this.profile, required this.weeklyLogs});

  @override
  Widget build(BuildContext context) {
    final now = DateTimeUtils.now();
    final weekDays = <String>[];
    final barGroups = <BarChartGroupData>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final dayLabel = i == 0 ? 'วันนี้' : DateFormat('E', 'th').format(date);
      weekDays.add(dayLabel);

      final logItem = weeklyLogs.firstWhere(
        (entry) => entry.date == dateKey,
        orElse: () => DailyLog(
          date: dateKey,
          caloriesIn: 0,
          waterGlasses: 0,
          foods: const [],
          workouts: const [],
          lastUpdated: date,
        ),
      );

      final isOver = logItem.caloriesIn > profile.targetCalories;
      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: logItem.caloriesIn.toDouble(),
              width: 16,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              gradient: LinearGradient(
                colors: isOver
                    ? [AppTheme.error.withValues(alpha: 0.6), AppTheme.error]
                    : [AppTheme.secondaryColor, AppTheme.primaryColor],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: profile.targetCalories.toDouble(),
                color: AppTheme.pageTintStrong,
              ),
            ),
          ],
        ),
      );
    }

    final maxLog = weeklyLogs.isEmpty
        ? profile.targetCalories.toDouble()
        : weeklyLogs
            .map((entry) => entry.caloriesIn)
            .reduce(math.max)
            .toDouble();

    return AppCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppTheme.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'แนวโน้มแคลอรี่ 7 วัน',
                  style: TextStyle(
                    fontSize: AppTheme.title,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.pageTintStrong,
                  borderRadius: AppTheme.pillRadius,
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  ),
                ),
                child: const Text(
                  'เป้าหมายรายวัน',
                  style: TextStyle(
                    fontSize: AppTheme.meta,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: AspectRatio(
              aspectRatio: 1.85,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: math.max(maxLog, profile.targetCalories.toDouble()) *
                      1.25,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: math.max(profile.targetCalories / 2, 1),
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFDCE7F5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            weekDays[value.toInt()],
                            style: const TextStyle(
                              fontSize: AppTheme.meta,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: profile.targetCalories.toDouble(),
                        color: AppTheme.warning.withValues(alpha: 0.65),
                        strokeWidth: 1.3,
                        dashArray: [5, 4],
                      ),
                    ],
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final int currentWater;
  final int targetWater;

  const _WaterCard({
    required this.currentWater,
    required this.targetWater,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        targetWater > 0 ? (currentWater / targetWater).clamp(0.0, 1.0) : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppTheme.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              AppIconBubble(
                color: AppTheme.waterColor,
                size: 36,
                child: Icon(
                  LucideIcons.droplet,
                  color: AppTheme.waterColor,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'น้ำดื่มวันนี้',
                  style: TextStyle(
                    fontSize: AppTheme.title,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '$currentWater / $targetWater แก้ว',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          TubeProgressBar(
            progress: progress,
            colors: const [AppTheme.secondaryColor, AppTheme.waterColor],
            backgroundColor: AppTheme.waterColor.withValues(alpha: 0.08),
            height: 10,
            borderRadius: 999,
          ),
          const SizedBox(height: 10),
          Text(
            progress >= 1
                ? 'ครบเป้าหมายแล้ว เยี่ยมมาก'
                : 'อีก ${targetWater - currentWater} แก้วจะครบเป้าหมาย',
            style: const TextStyle(
              fontSize: AppTheme.meta,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final TipItem tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBubble(
            color: tip.color,
            size: 36,
            child: Icon(
              LucideIcons.lightbulb,
              color: tip.color,
              size: 18,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Tip วันนี้',
            style: TextStyle(
              fontSize: AppTheme.meta,
              fontWeight: FontWeight.w700,
              color: tip.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tip.text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              tip.icon,
              color: tip.color.withValues(alpha: 0.22),
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}
