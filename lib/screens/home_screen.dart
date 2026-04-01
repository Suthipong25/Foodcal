import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_theme.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../widgets/tube_progress_bar.dart';

class TipItem {
  final String text;
  final IconData icon;
  final Color color;

  TipItem(this.text, this.icon, this.color);
}

final List<TipItem> _tips = [
  TipItem("ดื่มน้ำก่อนอาหาร 30 นาที ช่วยลดความอยากอาหารได้",
      LucideIcons.droplet, AppTheme.waterColor),
  TipItem("โปรตีนช่วยให้อิ่มนานและซ่อมแซมกล้ามเนื้อได้ดี", LucideIcons.beef,
      AppTheme.proteinColor),
  TipItem("จดอาหารทุกวันช่วยให้คุมแคลอรี่ได้แม่นขึ้น", LucideIcons.bookOpen,
      AppTheme.primaryColor),
  TipItem("นอนให้พอ 7-8 ชั่วโมง ช่วยคุมฮอร์โมนความหิว", LucideIcons.moon,
      AppTheme.fatColor),
];

class DashboardScreen extends StatelessWidget {
  final UserProfile profile;
  final DailyLog? log;
  final List<DailyLog> weeklyLogs;
  final Function(int) onSwitchTab;

  const DashboardScreen({
    Key? key,
    required this.profile,
    required this.log,
    required this.weeklyLogs,
    required this.onSwitchTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final caloriesIn = log?.caloriesIn ?? 0;
    final target = profile.targetCalories;
    final percentage = target > 0 ? (caloriesIn / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - caloriesIn;
    final isOver = caloriesIn > target;
    final currentProtein = log?.protein ?? 0;
    final currentCarbs = log?.carbs ?? 0;
    final currentFat = log?.fat ?? 0;
    final currentWater = log?.waterGlasses ?? 0;
    final todayTip = _tips[DateTime.now().day % _tips.length];

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageBackground()),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(
              caloriesIn: caloriesIn,
              target: target,
              remaining: remaining,
              isOver: isOver,
              percentage: percentage,
            ),
            const SizedBox(height: AppTheme.sectionGap),
            _buildSectionTitle(
                'ภาพรวมสารอาหาร', 'ดูว่ามื้อวันนี้ไปถึงเป้าหมายแค่ไหน'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMacroCard('โปรตีน', currentProtein, profile.targetProtein,
                    AppTheme.proteinColor, LucideIcons.beef),
                const SizedBox(width: 12),
                _buildMacroCard('คาร์บ', currentCarbs, profile.targetCarbs,
                    AppTheme.carbsColor, LucideIcons.sun),
                const SizedBox(width: 12),
                _buildMacroCard('ไขมัน', currentFat, profile.targetFat,
                    AppTheme.fatColor, LucideIcons.moon),
              ],
            ),
            const SizedBox(height: AppTheme.sectionGap),
            _buildSectionTitle(
                'ทางลัดประจำวัน', 'เข้าถึงสิ่งที่ใช้บ่อยให้เร็วขึ้น'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: LucideIcons.plus,
                    label: 'เพิ่มอาหาร',
                    subtitle: 'บันทึกมื้อใหม่',
                    color: AppTheme.primaryColor,
                    textColor: Colors.white,
                    onTap: () => onSwitchTab(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: LucideIcons.play,
                    label: 'ออกกำลังกาย',
                    subtitle: 'เปิดคลังวิดีโอ',
                    color: Colors.white,
                    textColor: AppTheme.ink,
                    iconColor: Colors.pinkAccent,
                    onTap: () => onSwitchTab(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.sectionGap),
            _buildWeeklyChart(),
            const SizedBox(height: AppTheme.sectionGap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildWaterCard(currentWater),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightCard(todayTip),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required int caloriesIn,
    required int target,
    required int remaining,
    required bool isOver,
    required double percentage,
  }) {
    final emphasisColor = isOver ? AppTheme.error : AppTheme.primaryColor;
    final ringBackground =
        isOver ? AppTheme.error.withOpacity(0.12) : AppTheme.pageTintStrong;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppTheme.tintedCard(emphasisColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                          ? 'วันนี้เกินเป้าหมายแล้ว ลองบาลานซ์มื้อถัดไป'
                          : 'ยังเหลือพลังงานสำหรับการกินอย่างสมดุล',
                      style: const TextStyle(
                        fontSize: AppTheme.body,
                        color: AppTheme.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              SizedBox(
                width: 144,
                height: 144,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 14,
                      valueColor: AlwaysStoppedAnimation(ringBackground),
                    ),
                    CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation(emphasisColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              isOver
                                  ? LucideIcons.alertTriangle
                                  : LucideIcons.zap,
                              color: emphasisColor,
                              size: 22),
                          const SizedBox(height: 6),
                          Text(
                            '$caloriesIn',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink),
                          ),
                          Text(
                            '/ $target kcal',
                            style: const TextStyle(
                                fontSize: AppTheme.meta,
                                color: AppTheme.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  label: isOver ? 'เกินเป้า' : 'เหลืออีก',
                  value: '${remaining.abs()} kcal',
                  icon: isOver ? LucideIcons.alertTriangle : LucideIcons.target,
                  color: emphasisColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  label: 'ดื่มน้ำเป้าหมาย',
                  value: '${profile.targetWaterGlasses} แก้ว',
                  icon: LucideIcons.droplet,
                  color: AppTheme.waterColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  label: 'Streak',
                  value: '${profile.streak} วัน',
                  icon: LucideIcons.flame,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
                Text(label,
                    style: const TextStyle(
                        fontSize: AppTheme.meta, color: AppTheme.mutedText)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: AppTheme.body,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: AppTheme.title,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontSize: AppTheme.body, color: AppTheme.mutedText)),
      ],
    );
  }

  Widget _buildMacroCard(
      String title, int current, int target, Color color, IconData icon) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - current;
    final isOver = remaining < 0;

    return Expanded(
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
                        color: AppTheme.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('$current / $target g',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink)),
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
              isOver ? 'เกิน ${remaining.abs()} g' : 'เหลือ ${remaining} g',
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

  Widget _buildWeeklyChart() {
    final now = DateTime.now();
    final barGroups = <BarChartGroupData>[];
    final weekDays = <String>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayName = i == 0 ? 'วันนี้' : DateFormat('E', 'th').format(date);
      weekDays.add(dayName);

      final logItem = weeklyLogs.firstWhere(
        (l) => l.date == dateStr,
        orElse: () => DailyLog(
          date: dateStr,
          caloriesIn: 0,
          waterGlasses: 0,
          foods: [],
          workouts: [],
          lastUpdated: date,
        ),
      );

      final val = logItem.caloriesIn.toDouble();
      final isOver = logItem.caloriesIn > profile.targetCalories;

      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: val,
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
        : weeklyLogs.map((e) => e.caloriesIn).reduce(math.max).toDouble();

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
                      color: AppTheme.ink),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.pageTintStrong,
                  borderRadius: AppTheme.pillRadius,
                ),
                child: const Text('เป้าหมายรายวัน',
                    style: TextStyle(
                        fontSize: AppTheme.meta,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.85,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (math.max(maxLog, profile.targetCalories.toDouble())) *
                    1.25,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: profile.targetCalories / 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.pageTintStrong,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
                              color: AppTheme.mutedText),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required Color textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 118,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppTheme.cardRadius,
                border: Border.all(
                    color: color == Colors.white
                        ? const Color(0xFFE2EBF8)
                        : color.withOpacity(0.2)),
                boxShadow: AppTheme.softShadow(
                    color == Colors.white ? AppTheme.primaryColor : color),
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
                      Text(label,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: AppTheme.meta,
                              color: textColor.withOpacity(0.75))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaterCard(int currentWater) {
    final progress = profile.targetWaterGlasses > 0
        ? (currentWater / profile.targetWaterGlasses).clamp(0.0, 1.0)
        : 0.0;

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
                child: const Icon(LucideIcons.droplet,
                    color: AppTheme.waterColor, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('น้ำดื่มวันนี้',
                    style: TextStyle(
                        fontSize: AppTheme.title,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('$currentWater / ${profile.targetWaterGlasses} แก้ว',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink)),
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
                : 'อีก ${profile.targetWaterGlasses - currentWater} แก้วจะครบเป้าหมาย',
            style: const TextStyle(
                fontSize: AppTheme.meta, color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(TipItem tip) {
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
            child: const Icon(LucideIcons.lightbulb,
                color: Colors.white, size: 18),
          ),
          const SizedBox(height: 18),
          const Text('Tip วันนี้',
              style: TextStyle(
                  fontSize: AppTheme.meta,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70)),
          const SizedBox(height: 6),
          Text(tip.text,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.45)),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.bottomRight,
            child:
                Icon(tip.icon, color: Colors.white.withOpacity(0.28), size: 44),
          ),
        ],
      ),
    );
  }
}
