import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../models/daily_log.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/edit_food_dialog.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;
    final screenWidth = MediaQuery.sizeOf(context).width;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบ')));
    }

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        title: const Text('ประวัติการบันทึก',
            style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<DailyLog>>(
        stream: firestoreService.streamDailyLogs(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.clipboardList, size: 64, color: AppTheme.mutedText),
                  SizedBox(height: 16),
                  Text('ยังไม่มีข้อมูลการบันทึก',
                      style: TextStyle(color: AppTheme.mutedText, fontSize: AppTheme.title)),
                ],
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppTheme.maxContentWidth(screenWidth)),
              child: ListView.builder(
                padding: AppTheme.pageInsetsForWidth(screenWidth, bottom: 32),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return _HistoryCard(log: logs[index], uid: user.uid);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final DailyLog log;
  final String uid;

  const _HistoryCard({required this.log, required this.uid});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  Future<void> _editWater() async {
    final ctrl = TextEditingController(text: widget.log.waterGlasses.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขการดื่มน้ำ'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'แก้ว', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text.trim())),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    if (result != null && result >= 0 && mounted) {
      await Provider.of<FirestoreService>(context, listen: false)
          .setWater(widget.uid, result, forDateKey: widget.log.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(widget.log.date);
    final formattedDate = date != null ? DateFormat('EEEEที่ d MMMM', 'th').format(date) : widget.log.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.softShadow(AppTheme.calorieColor),
        border: Border.all(color: AppTheme.calorieColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded ? const BorderRadius.vertical(top: Radius.circular(24)) : AppTheme.cardRadius,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formattedDate,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.ink)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.macroBg(AppTheme.calorieColor),
                          borderRadius: AppTheme.innerRadius,
                        ),
                        child: Text('${widget.log.caloriesIn} kcal',
                            style: const TextStyle(
                                color: AppTheme.calorieColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMacroInfo('🥩', '${widget.log.protein}g', AppTheme.proteinColor),
                      const SizedBox(width: 8),
                      _buildMacroInfo('🌾', '${widget.log.carbs}g', AppTheme.carbsColor),
                      const SizedBox(width: 8),
                      _buildMacroInfo('🥑', '${widget.log.fat}g', AppTheme.fatColor),
                      const SizedBox(width: 8),
                      _buildMacroInfo('🔥', '${widget.log.caloriesOut} kcal', AppTheme.warning),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _editWater,
                        child: _buildMacroInfo('💧', '${widget.log.waterGlasses}', AppTheme.waterColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Icon(_expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                        size: 20, color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('รายการอาหาร', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.ink)),
          const SizedBox(height: 10),
          if (widget.log.foods.isEmpty)
            const Text('ไม่มีรายการอาหาร', style: TextStyle(color: AppTheme.mutedText, fontSize: AppTheme.body))
          else
            ...widget.log.foods.map((food) => _buildFoodTile(food)),
          
          if (widget.log.workouts.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('การออกกำลังกาย', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.ink)),
            const SizedBox(height: 10),
            ...widget.log.workouts.map((w) => _buildWorkoutTile(w)),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodTile(FoodItem food) {
    return Dismissible(
      key: Key(food.id.isNotEmpty ? food.id : food.name + food.time.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 16),
        decoration: const BoxDecoration(color: Colors.red, borderRadius: AppTheme.innerRadius),
        alignment: Alignment.centerRight,
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 20),
      ),
      onDismissed: (_) async {
        if (food.id.isNotEmpty) {
          await Provider.of<FirestoreService>(context, listen: false)
              .removeFood(widget.uid, food.id, forDateKey: widget.log.date);
        }
      },
      child: InkWell(
        onTap: () async {
          final edited = await EditFoodDialog.show(context, existing: food);
          if (edited != null && edited.id.isNotEmpty && mounted) {
            await Provider.of<FirestoreService>(context, listen: false)
                .updateFoodItem(widget.uid, edited, forDateKey: widget.log.date);
          }
        },
        borderRadius: AppTheme.innerRadius,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppTheme.pageTint,
            borderRadius: AppTheme.innerRadius,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
                    Text('${food.mealType} • P${food.protein} C${food.carbs} F${food.fat}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.mutedText)),
                  ],
                ),
              ),
              Text('${food.calories} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutTile(WorkoutItem w) {
    final burned = FirestoreService.calculateWorkoutCalories(w);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withValues(alpha: 0.05),
        borderRadius: AppTheme.innerRadius,
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.dumbbell, size: 18, color: Colors.pinkAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
                Text('${w.type} • ${w.minutes} นาที',
                    style: const TextStyle(fontSize: 12, color: AppTheme.mutedText)),
              ],
            ),
          ),
          Text('$burned kcal', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
