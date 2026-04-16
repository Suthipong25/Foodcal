import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_theme.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../widgets/tube_progress_bar.dart';
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
    final todayTip = _tips[DateTime.now().day % _tips.length];

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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MacroCard(
                      title: 'โปรตีน',
                      current: currentProtein,
                      target: profile.targetProtein,
                      color: AppTheme.proteinColor,
                      icon: LucideIcons.beef,
                    ),
                    _MacroCard(
                      title: 'คาร์บ',
                      current: currentCarbs,
                      target: profile.targetCarbs,
                      color: AppTheme.carbsColor,
                      icon: LucideIcons.sun,
                    ),
                    _MacroCard(
                      title: 'ไขมัน',
                      current: currentFat,
                      target: profile.targetFat,
                      color: AppTheme.fatColor,
                      icon: LucideIcons.moon,
                    ),
                  ],
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
                    textColor: Colors.white,
                    onTap: () => onSwitchTab(1),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: LucideIcons.play,
                    title: 'ออกกำลังกาย',
                    subtitle: 'เปิดคลังวิดีโอ',
                    color: Colors.white,
                    textColor: AppTheme.ink,
                    iconColor: Colors.pinkAccent,
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
                          textColor: Colors.white,
                          onTap: () => onSwitchTab(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: LucideIcons.play,
                          title: 'ออกกำลังกาย',
                          subtitle: 'เปิดคลังวิดีโอ',
                          color: Colors.white,
                          textColor: AppTheme.ink,
                          iconColor: Colors.pinkAccent,
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
                  color: const Color(0xFFF3EEFF),
                  textColor: AppTheme.ink,
                  iconColor: const Color(0xFF6C3FF4),
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

    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 22),
      decoration: AppTheme.tintedCard(emphasis),
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(
                label: isOver ? 'เกินเป้า' : 'เหลืออีก',
                value: '${remainingCalories.abs()} kcal',
                icon: isOver ? LucideIcons.alertTriangle : LucideIcons.target,
                color: emphasis,
              ),
              _StatChip(
                label: 'เป้าหมายน้ำดื่ม',
                value: '${profile.targetWaterGlasses} แก้ว',
                icon: LucideIcons.droplet,
                color: AppTheme.waterColor,
              ),
              _StatChip(
                label: 'Streak',
                value: '${profile.streak} วัน',
                icon: LucideIcons.flame,
                color: AppTheme.warning,
              ),
            ],
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
          color: Colors.white.withOpacity(0.86),
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.title,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
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

    return SizedBox(
      width: 190,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.elevatedCard(
          color: Colors.white,
          borderColor: color.withOpacity(0.12),
          boxShadow: AppTheme.softShadow(color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTheme.body,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '$current / $target g',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            TubeProgressBar(
              progress: progress,
              colors: [color.withOpacity(0.55), color],
              backgroundColor: color.withOpacity(0.10),
              height: 8,
              borderRadius: 999,
            ),
            const SizedBox(height: 10),
            Text(
              isOver ? 'เกิน ${remaining.abs()} g' : 'เหลือ $remaining g',
              style: TextStyle(
                fontSize: AppTheme.meta,
                fontWeight: FontWeight.w700,
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
    final now = DateTime.now();
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
                    ? [AppTheme.error.withOpacity(0.6), AppTheme.error]
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.elevatedCard(
        color: Colors.white,
        borderColor: const Color(0xFFE3ECFA),
        boxShadow: AppTheme.softShadow(const Color(0xFF7CA7E9)),
      ),
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
                decoration: const BoxDecoration(
                  color: AppTheme.pageTintStrong,
                  borderRadius: AppTheme.pillRadius,
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
          AspectRatio(
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
                    color: AppTheme.pageTintStrong,
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
                      color: AppTheme.warning.withOpacity(0.45),
                      strokeWidth: 1.2,
                      dashArray: [5, 4],
                    ),
                  ],
                ),
                barGroups: barGroups,
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
  final Color textColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
    this.iconColor,
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
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppTheme.cardRadius,
          border: Border.all(
            color: color == Colors.white
                ? const Color(0xFFE2EBF8)
                : color.withOpacity(0.2),
          ),
          boxShadow: AppTheme.softShadow(
            color == Colors.white ? AppTheme.primaryColor : color,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color == Colors.white
                    ? AppTheme.pageTintStrong
                    : Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? textColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTheme.meta,
                    color: textColor.withOpacity(0.75),
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.elevatedCard(
        color: Colors.white,
        borderColor: AppTheme.waterColor.withOpacity(0.14),
        boxShadow: AppTheme.softShadow(AppTheme.waterColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.waterColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
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
            backgroundColor: AppTheme.waterColor.withOpacity(0.08),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tip.color.withOpacity(0.88), tip.color.withOpacity(0.68)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.softShadow(tip.color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.lightbulb,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tip วันนี้',
            style: TextStyle(
              fontSize: AppTheme.meta,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tip.text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              tip.icon,
              color: Colors.white.withOpacity(0.28),
              size: 44,
            ),
          ),
        ],
      ),
    );
  }
}
