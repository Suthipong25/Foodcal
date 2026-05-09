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
import '../widgets/glass_card.dart';
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
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = AppTheme.isCompactWidth(width);
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

    final uid = Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageBackground()),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: AppTheme.maxContentWidth(width)),
          child: SingleChildScrollView(
            padding: AppTheme.pageInsetsForWidth(width, bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<List<dynamic>>(
                  stream: fs.streamWeightLogs(uid, limit: 1),
                  builder: (context, snap) {
                    final logs = snap.data ?? [];
                    final hasWeight = logs.isNotEmpty && logs.first.date == FirestoreService.dateKey();
                    return DailyReminderColumn(
                      waterGlasses: currentWater,
                      targetWater: profile.targetWaterGlasses,
                      hasFoodToday: caloriesIn > 0,
                      hasWeightToday: hasWeight,
                    );
                  },
                ),
                _HeroCard(
                  profile: profile,
                  caloriesIn: caloriesIn,
                  targetCalories: targetCalories,
                  remainingCalories: remainingCalories,
                  progress: progress,
                  isCompact: isCompact,
                ),
                const SizedBox(height: AppTheme.sectionGap),
                const _SectionHeader(
                  title: 'ภาพรวมสารอาหาร',
                  subtitle: 'ดูว่าวันนี้เราเข้าใกล้เป้าหมายมากแค่ไหน',
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      _MacroCard(
                        title: 'โปรตีน',
                        current: currentProtein,
                        target: profile.targetProtein,
                        color: AppTheme.proteinColor,
                        icon: LucideIcons.beef,
                      ),
                      const SizedBox(width: 12),
                      _MacroCard(
                        title: 'คาร์บ',
                        current: currentCarbs,
                        target: profile.targetCarbs,
                        color: AppTheme.carbsColor,
                        icon: LucideIcons.sun,
                      ),
                      const SizedBox(width: 12),
                      _MacroCard(
                        title: 'ไขมัน',
                        current: currentFat,
                        target: profile.targetFat,
                        color: AppTheme.fatColor,
                        icon: LucideIcons.moon,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.sectionGap),
                const _SectionHeader(
                  title: 'ทางลัดประจำวัน',
                  subtitle: 'เข้าถึงสิ่งที่ใช้บ่อยให้เร็วขึ้น',
                ),
                const SizedBox(height: 12),
                if (isCompact) ...[
                  _ActionCard(
                    icon: LucideIcons.plus,
                    title: 'เพิ่มอาหาร',
                    subtitle: 'บันทึกมื้อใหม่',
                    color: AppTheme.primaryColor,
                    onTap: () => onSwitchTab(1),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: LucideIcons.play,
                    title: 'ออกกำลังกาย',
                    subtitle: 'เปิดคลังวิดีโอ',
                    color: AppTheme.warning,
                    onTap: () => onSwitchTab(2),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: LucideIcons.plus,
                          title: 'เพิ่มอาหาร',
                          subtitle: 'บันทึกมื้อใหม่',
                          color: AppTheme.primaryColor,
                          onTap: () => onSwitchTab(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: LucideIcons.play,
                          title: 'ออกกำลังกาย',
                          subtitle: 'เปิดคลังวิดีโอ',
                          color: AppTheme.warning,
                          onTap: () => onSwitchTab(2),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: LucideIcons.messageSquare,
                  title: 'AI Coach',
                  subtitle: 'รับคำแนะนำเรื่องอาหาร พฤติกรรม และการฟื้นตัว',
                  color: AppTheme.aiColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AICoachScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.sectionGap),
                _WeeklyChart(profile: profile, weeklyLogs: weeklyLogs),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final UserProfile profile;
  final int caloriesIn;
  final int targetCalories;
  final int remainingCalories;
  final double progress;
  final bool isCompact;

  const _HeroCard({
    required this.profile,
    required this.caloriesIn,
    required this.targetCalories,
    required this.remainingCalories,
    required this.progress,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = remainingCalories < 0;
    final emphasis = isOver ? AppTheme.error : AppTheme.primaryColor;

    return GlassCard(
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      opacity: 0.18,
      borderColor: const Color(0xFFDDE8F4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact) ...[
            _HeroText(isOver: isOver),
            const SizedBox(height: 18),
            Center(
              child: _HeroRing(
                progress: progress,
                caloriesIn: caloriesIn,
                targetCalories: targetCalories,
                emphasis: emphasis,
                compact: true,
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(child: _HeroText(isOver: isOver)),
                const SizedBox(width: 18),
                _HeroRing(
                  progress: progress,
                  caloriesIn: caloriesIn,
                  targetCalories: targetCalories,
                  emphasis: emphasis,
                  compact: false,
                ),
              ],
            ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _StatChip(
                  label: isOver ? 'เกินเป้า' : 'เหลืออีก',
                  value: '${remainingCalories.abs()} kcal',
                  icon: isOver ? LucideIcons.alertTriangle : LucideIcons.target,
                  color: emphasis,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'เป้าหมายน้ำดื่ม',
                  value: '${profile.targetWaterGlasses} แก้ว',
                  icon: LucideIcons.droplet,
                  color: AppTheme.waterColor,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  label: 'Streak',
                  value: '${profile.streak} วัน',
                  icon: LucideIcons.flame,
                  color: AppTheme.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final bool isOver;

  const _HeroText({required this.isOver});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'แดชบอร์ดวันนี้',
          style: TextStyle(
            fontSize: AppTheme.largeTitle,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isOver
              ? 'วันนี้เกินเป้าหมายแล้ว ลองบาลานซ์มื้อถัดไปให้เบาขึ้น'
              : 'ยังเหลือพลังงานสำหรับการกินอย่างสมดุลในวันนี้',
          style: const TextStyle(
            fontSize: AppTheme.body,
            color: AppTheme.mutedText,
            height: 1.4,
          ),
        ),
      ],
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
          const CircularProgressIndicator(
            value: 1,
            strokeWidth: 14,
            valueColor: AlwaysStoppedAnimation(AppTheme.pageTintStrong),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 14,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation(emphasis),
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 186,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: const Color(0xFFDDE8F4)),
          boxShadow: AppTheme.softShadow(color),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: AppTheme.meta,
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.pageTintStrong,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.10),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.meta,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
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

class _MacroCard extends StatelessWidget {
  final String title;
  final int current;
  final int target;
  final Color color;
  final IconData icon;

  const _MacroCard({
    required this.title,
    required this.current,
    required this.target,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - current;
    final isOver = remaining < 0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      opacity: 0.16,
      borderColor: const Color(0xFFDDE8F4),
      child: SizedBox(
        width: 158,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: AppTheme.iconBubble(color),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$current / $target g',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            TubeProgressBar(
              progress: progress,
              colors: [color.withValues(alpha: 0.55), color],
              backgroundColor: color.withValues(alpha: 0.10),
              height: 6,
              borderRadius: 999,
            ),
            const SizedBox(height: 8),
            Text(
              isOver ? 'เกิน ${remaining.abs()} g' : 'เหลือ $remaining g',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isOver ? AppTheme.error : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
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

    return GlassCard(
      padding: const EdgeInsets.all(20),
      opacity: 0.18,
      borderColor: const Color(0xFFDDE8F4),
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
              border: Border.all(color: const Color(0xFFE4EDF8)),
            ),
            child: AspectRatio(
              aspectRatio: 1.85,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      math.max(maxLog, profile.targetCalories.toDouble()) * 1.25,
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 118,
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.subtleCard(
          background: Colors.white,
          borderColor: const Color(0xFFDDE8F4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: AppTheme.iconBubble(color),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: AppTheme.meta,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
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

    return GlassCard(
      padding: const EdgeInsets.all(18),
      opacity: 0.16,
      borderColor: const Color(0xFFDDE8F4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: AppTheme.iconBubble(AppTheme.waterColor),
                child: const Icon(
                  LucideIcons.droplet,
                  color: AppTheme.waterColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.subtleCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: AppTheme.iconBubble(tip.color),
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
