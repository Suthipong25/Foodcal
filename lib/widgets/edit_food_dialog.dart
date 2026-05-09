import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_theme.dart';
import '../constants/app_config.dart';
import '../models/daily_log.dart';
import '../utils/datetime_utils.dart';

/// A bottom-sheet dialog for creating or editing a [FoodItem].
///
/// Returns the edited [FoodItem] when the user confirms, or null when cancelled.
class EditFoodDialog extends StatefulWidget {
  final FoodItem? existing; // null = create new

  const EditFoodDialog({super.key, this.existing});

  /// Convenience: show as a modal bottom-sheet and await the result.
  static Future<FoodItem?> show(BuildContext context, {FoodItem? existing}) {
    return showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditFoodDialog(existing: existing),
    );
  }

  @override
  State<EditFoodDialog> createState() => _EditFoodDialogState();
}

class _EditFoodDialogState extends State<EditFoodDialog> {
  static const int _maxCal = 5000;
  static const int _maxMacro = 500;

  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  String _mealType = AppConfig.mealTypeSnack;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final f = widget.existing!;
      _nameCtrl.text = f.name;
      _calCtrl.text = f.calories.toString();
      _proteinCtrl.text = f.protein.toString();
      _carbsCtrl.text = f.carbs.toString();
      _fatCtrl.text = f.fat.toString();
      _mealType = f.mealType;
    } else {
      _mealType = _suggestMealType();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  String _suggestMealType() {
    return DateTimeUtils.getCurrentMealType();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final cal = int.tryParse(_calCtrl.text.trim());
    final protein = int.tryParse(_proteinCtrl.text.trim()) ?? 0;
    final carbs = int.tryParse(_carbsCtrl.text.trim()) ?? 0;
    final fat = int.tryParse(_fatCtrl.text.trim()) ?? 0;

    String? error;
    if (name.isEmpty) {
      error = 'กรุณากรอกชื่ออาหาร';
    } else if (cal == null || cal < 0) {
      error = 'กรุณากรอกแคลอรี่ให้ถูกต้อง';
    } else if ([cal, protein, carbs, fat].any((v) => v < 0)) {
      error = 'ค่าต้องไม่ติดลบ';
    } else if (cal > _maxCal || protein > _maxMacro || carbs > _maxMacro || fat > _maxMacro) {
      error = 'ค่าสูงเกินช่วงที่อนุญาต';
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final result = FoodItem(
      id: widget.existing?.id, // preserve existing id; null → empty → will be assigned later
      name: name,
      calories: cal!,
      protein: protein,
      carbs: carbs,
      fat: fat,
      time: widget.existing?.time ?? DateTimeUtils.now(),
      mealType: _mealType,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44, height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[300], borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isEdit ? LucideIcons.pencil : LucideIcons.plus,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _isEdit ? 'แก้ไขรายการอาหาร' : 'เพิ่มอาหาร',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _field(_nameCtrl, 'ชื่ออาหาร', TextInputType.text, icon: LucideIcons.tag),
                const SizedBox(height: 14),
                _field(_calCtrl, 'พลังงาน (แคลอรี่)', TextInputType.number, icon: LucideIcons.zap, suffix: 'kcal'),
                const SizedBox(height: 20),
                const Text('ข้อมูลโภชนาการ (กรัม)', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.mutedText, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_proteinCtrl, 'โปรตีน', TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_carbsCtrl, 'คาร์บ', TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_fatCtrl, 'ไขมัน', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('มื้ออาหาร',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.mutedText)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      _mealChip('เช้า', AppConfig.mealTypeBreakfast, LucideIcons.sunrise),
                      const SizedBox(width: 8),
                      _mealChip('กลางวัน', AppConfig.mealTypeLunch, LucideIcons.sun),
                      const SizedBox(width: 8),
                      _mealChip('เย็น', AppConfig.mealTypeDinner, LucideIcons.sunset),
                      const SizedBox(width: 8),
                      _mealChip('ว่าง', AppConfig.mealTypeSnack, LucideIcons.coffee),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(AppTheme.buttonHeight),
                      shape: const RoundedRectangleBorder(borderRadius: AppTheme.innerRadius),
                      elevation: 0,
                    ),
                    child: Text(
                      _isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มรายการ',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, TextInputType type, {IconData? icon, String? suffix}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.mutedText.withValues(alpha: 0.5), fontWeight: FontWeight.normal),
        prefixIcon: icon != null ? Icon(icon, size: 18) : null,
        suffixText: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _mealChip(String label, String value, IconData icon) {
    final selected = _mealType == value;
    return GestureDetector(
      onTap: () => setState(() => _mealType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.grey[200]!,
          ),
          boxShadow: selected ? AppTheme.softShadow(AppTheme.primaryColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : AppTheme.mutedText, size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
