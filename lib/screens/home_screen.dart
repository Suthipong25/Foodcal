
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../models/daily_log.dart';
import 'dart:math' as math;
import '../widgets/tube_progress_bar.dart';
import '../app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/ai_service.dart'; // For scanning from home if needed later
import 'package:image_picker/image_picker.dart';

class TipItem {
  final String text;
  final IconData icon;
  final Color color;

  TipItem(this.text, this.icon, this.color);
}

final List<TipItem> _tips = [
  // Nutrition
  TipItem("ดื่มน้ำก่อนอาหาร 30 นาที ช่วยลดความอยากอาหารได้ 15%", LucideIcons.droplet, Colors.blue),
  TipItem("ข้าวมันไก่ (ไม่หนัง) แคลอรี่ลดลงกว่า 100 kcal", LucideIcons.utensils, Colors.orange),
  TipItem("การเคี้ยวอาหารช้าๆ ช่วยให้อิ่มเร็วขึ้นและย่อยง่าย", LucideIcons.smile, Colors.green),
  TipItem("โปรตีนช่วยซ่อมแซมกล้ามเนื้อ ควรทานหลังออกกำลังกาย", LucideIcons.beef, Colors.red),
  TipItem("ลดน้ำตาลในเครื่องดื่ม ช่วยลดไขมันสะสมหน้าท้องได้", LucideIcons.cupSoda, Colors.brown),
  TipItem("ไฟเบอร์จากผักช่วยชะลอการดูดซึมน้ำตาลเข้ากระแสเลือด", LucideIcons.carrot, Colors.green),
  // Exercise
  TipItem("เดินเร็ว 30 นาที เผาผลาญได้ประมาณ 150 kcal", LucideIcons.footprints, Colors.purple),
  TipItem("การเวทเทรนนิ่งช่วยเพิ่มอัตราการเผาผลาญระยะยาว", LucideIcons.dumbbell, Colors.blueGrey),
  TipItem("คาดิโอตอนเช้าขณะท้องว่าง อาจช่วยดึงไขมันมาใช้ได้ดี", LucideIcons.sun, Colors.orange),
  TipItem("ยืดเหยียดกล้ามเนื้อหลังออกกำลังกาย ลดอาการบาดเจ็บ", LucideIcons.activity, Colors.pink),
  // Health & Lifestyle
  TipItem("การนอนหลับ 7-8 ชั่วโมง ช่วยควบคุมฮอร์โมนความหิว", LucideIcons.moon, Colors.indigo),
  TipItem("ความเครียดทำให้ร่างกายสะสมไขมันมากขึ้น", LucideIcons.frown, Colors.grey),
  TipItem("การจดบันทึกอาหาร ช่วยให้ลดน้ำหนักสำเร็จเพิ่มขึ้น 2 เท่า", LucideIcons.bookOpen, Colors.teal),
  TipItem("ชั่งน้ำหนักสัปดาห์ละ 1 ครั้ง เพียงพอแล้ว", LucideIcons.scale, Colors.cyan),
  TipItem("ดื่มกาแฟดำไม่ใส่น้ำตาล ช่วยกระตุ้นการเผาผลาญ", LucideIcons.coffee, Colors.brown),
  TipItem("แอปเปิ้ลเขียวมีน้ำตาลน้อยกว่าแอปเปิ้ลแดง", LucideIcons.apple, Colors.lightGreen),
  TipItem("ไข่ต้ม 1 ฟอง ให้โปรตีนประมาณ 6-7 กรัม", LucideIcons.egg, Colors.yellow),
  TipItem("การดื่มน้ำเย็น ร่างกายต้องใช้พลังงานปรับอุณหภูมิเล็กน้อย", LucideIcons.snowflake, Colors.lightBlue),
  TipItem("ควรขยับร่างกายทุกๆ 1 ชั่วโมง หากนั่งทำงานนาน", LucideIcons.clock, Colors.deepPurple),
  TipItem("ลดของทอดของมันเพียงวันละมื้อ ช่วยลดแคลอรี่ได้มหาศาล", LucideIcons.ban, Colors.red),
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
    int caloriesIn = log?.caloriesIn ?? 0;
    int target = profile.targetCalories;
    double percentage = (caloriesIn / target).clamp(0.0, 1.0);
    int remaining = target - caloriesIn;
    bool isOver = caloriesIn > target;

    // Actual macros from log
    int currentProtein = log?.protein ?? 0;
    int currentCarbs = log?.carbs ?? 0;
    int currentFat = log?.fat ?? 0;

    Color progressColor = isOver ? AppTheme.error : AppTheme.calorieColor;
    if (!isOver && percentage > 0.8) progressColor = AppTheme.calorieColor.withOpacity(0.8);
    if (!isOver && percentage >= 1.0) progressColor = AppTheme.calorieColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Calorie Over Limit Alert
          if (isOver) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Row(
                children: [
                   const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 20),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       'แคลอรี่วันนี้เกินกำหนดไป ${caloriesIn - target} kcal แล้วนะ!',
                       style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                     ),
                   ),
                ],
              ),
            ),
          ],

          // Next Meal Budget Card (New)
          if (!isOver && remaining > 0) _buildNextMealBudget(remaining, target),
          
          if (isOver) const SizedBox(height: 16),

          // Circular Progress Card (Compact)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.cardRadius,
              border: Border.all(color: (isOver ? AppTheme.error : AppTheme.calorieColor).withOpacity(0.1)),
              boxShadow: AppTheme.softShadow(isOver ? AppTheme.error : AppTheme.calorieColor),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('แคลอรี่วันนี้', style: TextStyle(color: Colors.blueGrey[400], fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(isOver ? '+${caloriesIn - target}' : '$remaining', 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isOver ? Colors.redAccent : Colors.blue[600])),
                            Text(isOver ? 'เกิน (kcal)' : 'เหลือ (kcal)', style: TextStyle(fontSize: 10, color: isOver ? Colors.red[300] : Colors.blueGrey[200])),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            valueColor: AlwaysStoppedAnimation(isOver ? Colors.red[50] : Colors.blue[50]),
                            strokeWidth: 14,
                          ),
                          CircularProgressIndicator(
                            value: percentage,
                            valueColor: AlwaysStoppedAnimation(progressColor),
                            strokeWidth: 14,
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isOver ? LucideIcons.frown : LucideIcons.zap, color: progressColor, size: 24),
                                Text('$caloriesIn', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -1)),
                                Text('/ $target kcal', style: TextStyle(fontSize: 10, color: Colors.blueGrey[300], fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacro(
                          'โปรตีน', 
                          currentProtein, 
                          profile.targetProtein, 
                          AppTheme.proteinColor
                        ),
                        _buildMacro(
                          'คาร์บ', 
                          currentCarbs, 
                          profile.targetCarbs, 
                          AppTheme.carbsColor
                        ),
                        _buildMacro(
                          'ไขมัน', 
                          currentFat, 
                          profile.targetFat, 
                          AppTheme.fatColor
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: -40, right: -40, 
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(color: (isOver ? Colors.red : Colors.blue).withOpacity(0.03), shape: BoxShape.circle),
                  )
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Weekly Summary Chart
          _buildWeeklyChart(),
          
          const SizedBox(height: 16),

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: LucideIcons.plus,
                  label: 'จดอาหาร',
                  color: Colors.green,
                  textColor: Colors.white,
                  onTap: () => onSwitchTab(1), // Index for Track
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  icon: LucideIcons.play,
                  label: 'ออกกำลังกาย',
                  color: Colors.white,
                  textColor: Colors.grey[800]!,
                  iconColor: Colors.pink,
                  onTap: () => onSwitchTab(2), // Index for Content
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          
          // Water Progress Card (Dashboard)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppTheme.cardRadius,
              border: Border.all(color: AppTheme.waterColor.withOpacity(0.1)),
              boxShadow: AppTheme.softShadow(AppTheme.waterColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(LucideIcons.droplet, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text('ดื่มน้ำวันนี้', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${log?.waterGlasses ?? 0} / ${profile.targetWaterGlasses} แก้ว', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 16),
                TubeProgressBar(
                  progress: (profile.targetWaterGlasses > 0 
                    ? (log?.waterGlasses ?? 0) / profile.targetWaterGlasses 
                    : 0.0).clamp(0.0, 1.0),
                  colors: [Colors.blue[300]!, Colors.blue[500]!],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Insight Card (Dynamic)
          Builder(
            builder: (context) {
              // Random selection based on timestamp to change periodically or simple random
              // Using simple random will change on every rebuild.
              // To make it change "when changing pages" but stable within the view, 
              // we rely on the fact that switching tabs in some setups rebuilds.
              // If IndexedStack preserves state, this might be static.
              // Let's use Random from current time microsecond to ensure variety.
              final tip = _tips[math.Random().nextInt(_tips.length)];
              
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: tip.color.withOpacity(0.8),
                  borderRadius: AppTheme.cardRadius,
                  boxShadow: AppTheme.softShadow(tip.color),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.lightbulb, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('รู้หรือไม่?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(tip.text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                      ],
                    ),
                    Positioned(
                      right: -10, bottom: -10,
                      child: Icon(tip.icon, size: 80, color: Colors.white.withOpacity(0.2)),
                    )
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    // Prepare data for the last 7 days
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    final List<String> weekDays = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayName = i == 0 ? 'วันนี้' : DateFormat('E', 'th').format(date);
      weekDays.add(dayName);

      // Find log for this date
      final log = weeklyLogs.firstWhere(
        (l) => l.date == dateStr, 
        orElse: () => DailyLog(
          date: dateStr, 
          caloriesIn: 0, 
          waterGlasses: 0, 
          foods: [], 
          workouts: [], 
          lastUpdated: date
        )
      );

      final double val = log.caloriesIn.toDouble();
      final bool isOver = log.caloriesIn > profile.targetCalories;

      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: val,
              gradient: LinearGradient(
                colors: isOver 
                  ? [Colors.redAccent.withOpacity(0.7), Colors.redAccent] 
                  : [AppTheme.calorieColor.withOpacity(0.7), AppTheme.calorieColor],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: profile.targetCalories.toDouble(),
                color: Colors.blue[50]!.withOpacity(0.5),
              ),
            ),
          ],
          showingTooltipIndicators: val > 0 ? [0] : [],
        ),
      );
    }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.cardRadius,
          border: Border.all(color: Colors.blue[50]!),
          boxShadow: AppTheme.softShadow(Colors.blueGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('สรุปรายสัปดาห์ (แคลอรี่)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Icon(LucideIcons.barChart2, color: Colors.blueGrey[300], size: 18),
              ],
            ),
            const SizedBox(height: 32), // More space for top labels
            AspectRatio(
              aspectRatio: 2.0, // More compact
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (weeklyLogs.isEmpty ? profile.targetCalories : 
                         weeklyLogs.map((e) => e.caloriesIn).reduce(math.max).toDouble()) * 1.3,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 4,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.round().toString(),
                          TextStyle(
                            color: rod.toY > profile.targetCalories ? Colors.redAccent : Colors.blueGrey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              weekDays[value.toInt()],
                              style: TextStyle(color: Colors.blueGrey[300], fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: profile.targetCalories.toDouble(),
                        color: Colors.orange.withOpacity(0.4),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: TextStyle(color: Colors.orange.withOpacity(0.6), fontSize: 8, fontWeight: FontWeight.bold),
                          labelResolver: (_) => 'เป้าหมาย',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildMacro(String label, int current, int target, Color color) {
    int remaining = target - current;
    bool isOver = remaining < 0;
    double progress = (target > 0 ? current / target : 0.0).clamp(0.0, 1.0);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.macroBg(color), 
          borderRadius: AppTheme.innerRadius,
          border: Border.all(color: AppTheme.macroBorder(color)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
            const SizedBox(height: 8),
            // Minimalist Linear Progress Bar (Tube)
            TubeProgressBar(
              progress: progress,
              colors: [isOver ? AppTheme.error : color.withOpacity(0.6), isOver ? AppTheme.error : color],
              backgroundColor: color.withOpacity(0.1),
              height: 6,
              borderRadius: 4,
            ),
            const SizedBox(height: 8),
            Text(
              isOver ? '+${remaining.abs()}g' : '${remaining}g', 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isOver ? AppTheme.error : color)
            ),
            Text(
              isOver ? 'เกิน' : 'เหลือ', 
              style: TextStyle(fontSize: 9, color: isOver ? AppTheme.error.withOpacity(0.6) : color.withOpacity(0.4), fontWeight: FontWeight.w500)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: iconColor ?? textColor),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildNextMealBudget(int remaining, int target) {
    final now = DateTime.now();
    final hour = now.hour;
    String mealName = 'มื้อถัดไป';
    int budget = 0;
    IconData icon = LucideIcons.utensils;

    if (hour >= 5 && hour < 10) {
      mealName = 'มื้อเช้า';
      budget = (target * 0.25).round();
      icon = LucideIcons.sunrise;
    } else if (hour >= 10 && hour < 15) {
      mealName = 'มื้อกลางวัน';
      budget = (target * 0.35).round();
      icon = LucideIcons.sun;
    } else if (hour >= 15 && hour < 21) {
      mealName = 'มื้อเย็น';
      budget = (target * 0.30).round();
      icon = LucideIcons.sunset;
    } else {
      mealName = 'มื้อว่าง/มื้อดึก';
      budget = (target * 0.10).round();
      icon = LucideIcons.moon;
    }

    // Ensure budget doesn't exceed remaining
    if (budget > remaining) budget = remaining;
    if (budget < 0) budget = 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.blueAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('งบประมาณสำหรับ $mealName', style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('แนะนำให้ทานไม่เกิน $budget kcal', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Text('${((budget / target) * 100).round()}%', style: TextStyle(color: Colors.blueAccent.withOpacity(0.3), fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
