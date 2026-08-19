import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_theme.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../utils/datetime_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/organic_page.dart';
import '../widgets/reminder_banner.dart';
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

    return OrganicPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrganicScreenTitle(
            title: 'Foodcal',
            subtitle: 'Daily Control Center',
          ),
          const SizedBox(height: 14),
          _TodayHero(
            caloriesIn: caloriesIn,
            targetCalories: targetCalories,
            remainingCalories: remainingCalories,
            progress: progress,
            onScan: () => onSwitchTab(1),
          ),
          const SizedBox(height: 12),
          DailyReminderColumn(
            waterGlasses: currentWater,
            targetWater: profile.targetWaterGlasses,
            hasFoodToday: caloriesIn > 0,
            hasWeightToday: false,
          ),
          const SizedBox(height: 14),
          _MacroGrid(
            protein: currentProtein,
            proteinTarget: profile.targetProtein,
            carbs: currentCarbs,
            carbsTarget: profile.targetCarbs,
            fat: currentFat,
            fatTarget: profile.targetFat,
          ),
          const SizedBox(height: 14),
          _WeeklyChart(profile: profile, weeklyLogs: weeklyLogs),
          const SizedBox(height: 14),
          if (width >= 700)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _MealTimeline(log: log)),
                const SizedBox(width: 14),
                Expanded(
                  child: _SideStack(
                    currentWater: currentWater,
                    targetWater: profile.targetWaterGlasses,
                    tip: todayTip,
                    onSwitchTab: onSwitchTab,
                  ),
                ),
              ],
            )
          else ...[
            _MealTimeline(log: log),
            const SizedBox(height: 14),
            _SideStack(
              currentWater: currentWater,
              targetWater: profile.targetWaterGlasses,
              tip: todayTip,
              onSwitchTab: onSwitchTab,
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  final int caloriesIn;
  final int targetCalories;
  final int remainingCalories;
  final double progress;
  final VoidCallback onScan;

  const _TodayHero({
    required this.caloriesIn,
    required this.targetCalories,
    required this.remainingCalories,
    required this.progress,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = remainingCalories < 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.softShadow(AppTheme.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE d MMM', 'th')
                          .format(DateTimeUtils.now()),
                      style: const TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOver
                          ? 'เกินเป้า ${remainingCalories.abs()} kcal'
                          : 'เหลืออีก $remainingCalories kcal',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                  ],
                ),
              ),
              _ProgressDial(
                progress: progress,
                color: isOver ? AppTheme.error : AppTheme.secondaryColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'วันนี้',
                  value: '$caloriesIn',
                  unit: 'kcal',
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'เป้าหมาย',
                  value: '$targetCalories',
                  unit: 'kcal',
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(LucideIcons.scan, size: 18),
              label: const Text('สแกนหรือบันทึกอาหาร'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppTheme.innerRadius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDial extends StatelessWidget {
  final double progress;
  final Color color;

  const _ProgressDial({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 9,
            strokeCap: StrokeCap.round,
            backgroundColor: AppTheme.pageTintStrong,
            color: color,
          ),
          Center(
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroGrid extends StatelessWidget {
  final int protein;
  final int proteinTarget;
  final int carbs;
  final int carbsTarget;
  final int fat;
  final int fatTarget;

  const _MacroGrid({
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroTile(
            label: 'Protein',
            value: protein,
            target: proteinTarget,
            color: AppTheme.proteinColor,
            icon: LucideIcons.beef,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroTile(
            label: 'Carbs',
            value: carbs,
            target: carbsTarget,
            color: AppTheme.carbsColor,
            icon: LucideIcons.zap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MacroTile(
            label: 'Fat',
            value: fat,
            target: fatTarget,
            color: AppTheme.fatColor,
            icon: LucideIcons.heart,
          ),
        ),
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final int value;
  final int target;
  final Color color;
  final IconData icon;

  const _MacroTile({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(13),
      borderColor: color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 10),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$value/$target g',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          TubeProgressBar(
            progress: progress,
            colors: [color.withValues(alpha: 0.55), color],
            backgroundColor: color.withValues(alpha: 0.12),
            height: 7,
            borderRadius: 999,
          ),
        ],
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
    final labels = <String>[];
    final barGroups = <BarChartGroupData>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      labels.add(i == 0 ? 'วันนี้' : DateFormat('E', 'th').format(date));

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
              width: 18,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              color: isOver ? AppTheme.error : AppTheme.primaryColor,
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'แนวโน้ม 7 วัน',
            icon: LucideIcons.barChart2,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
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
                    color: AppTheme.cardBorder,
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
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt().clamp(0, labels.length - 1);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: const TextStyle(
                              fontSize: AppTheme.meta,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: profile.targetCalories.toDouble(),
                      color: AppTheme.warning.withValues(alpha: 0.75),
                      strokeWidth: 1.3,
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

class _MealTimeline extends StatelessWidget {
  final DailyLog? log;

  const _MealTimeline({required this.log});

  @override
  Widget build(BuildContext context) {
    final foods = log?.foods.reversed.take(5).toList() ?? [];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'มื้อวันนี้',
            icon: LucideIcons.bookOpen,
            color: AppTheme.accentColor,
          ),
          const SizedBox(height: 14),
          if (foods.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.pageTint,
                borderRadius: AppTheme.innerRadius,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Text(
                'ยังไม่มีรายการอาหารวันนี้',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...foods.map((food) => _FoodRow(food: food)),
        ],
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  final FoodItem food;

  const _FoodRow({required this.food});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.pageTint,
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppTheme.pageBg,
              borderRadius: AppTheme.innerRadius,
            ),
            child: const Icon(
              LucideIcons.utensils,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${food.mealType} · P ${food.protein}g / C ${food.carbs}g / F ${food.fat}g',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${food.calories}',
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideStack extends StatelessWidget {
  final int currentWater;
  final int targetWater;
  final TipItem tip;
  final Function(int) onSwitchTab;

  const _SideStack({
    required this.currentWater,
    required this.targetWater,
    required this.tip,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WaterCard(currentWater: currentWater, targetWater: targetWater),
        const SizedBox(height: 14),
        _TipCard(tip: tip),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OrganicActionTile(
                icon: LucideIcons.plus,
                title: 'บันทึกอาหาร',
                subtitle: 'เพิ่มมื้อใหม่',
                color: AppTheme.primaryColor,
                onTap: () => onSwitchTab(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OrganicActionTile(
                icon: LucideIcons.messageCircle,
                title: 'AI Coach',
                subtitle: 'ช่วยคิดเมนู',
                color: AppTheme.aiColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AICoachScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
      borderColor: AppTheme.waterColor.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'น้ำดื่ม',
            icon: LucideIcons.droplet,
            color: AppTheme.waterColor,
          ),
          const SizedBox(height: 16),
          Text(
            '$currentWater / $targetWater แก้ว',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          TubeProgressBar(
            progress: progress,
            colors: const [AppTheme.waterColor, AppTheme.secondaryColor],
            backgroundColor: AppTheme.waterColor.withValues(alpha: 0.1),
            height: 10,
            borderRadius: 999,
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
      borderColor: tip.color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Tip วันนี้',
            icon: tip.icon,
            color: tip.color,
          ),
          const SizedBox(height: 12),
          Text(
            tip.text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppTheme.innerRadius,
          ),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
