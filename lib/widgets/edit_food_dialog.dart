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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _isEdit ? LucideIcons.pencil : LucideIcons.plus,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEdit ? 'แก้ไขรายการอาหาร' : 'เพิ่มอาหาร',
                      style: const TextStyle(
                          fontSize: AppTheme.title,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _field(_nameCtrl, 'ชื่ออาหาร', TextInputType.text),
                const SizedBox(height: 12),
                _field(_calCtrl, 'แคลอรี่ (kcal)', TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(_proteinCtrl, 'โปรตีน (g)', TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_carbsCtrl, 'คาร์บ (g)', TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_fatCtrl, 'ไขมัน (g)', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('มื้ออาหาร',
                    style: TextStyle(
                        fontSize: AppTheme.meta,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedText)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _mealChip(
                        'เช้า', AppConfig.mealTypeBreakfast, LucideIcons.sunrise),
                    _mealChip(
                        'กลางวัน', AppConfig.mealTypeLunch, LucideIcons.sun),
                    _mealChip(
                        'เย็น', AppConfig.mealTypeDinner, LucideIcons.sunset),
                    _mealChip(
                        'ว่าง', AppConfig.mealTypeSnack, LucideIcons.coffee),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(AppTheme.buttonHeight),
                      shape: const RoundedRectangleBorder(borderRadius: AppTheme.innerRadius),
                    ),
                    child: Text(
                      _isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มรายการ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _field(TextEditingController ctrl, String hint, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppTheme.pageTint,
        border: const OutlineInputBorder(
          borderRadius: AppTheme.innerRadius,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _mealChip(String label, String value, IconData icon) {
    final selected = _mealType == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 14),
      selected: selected,
      onSelected: (_) => setState(() => _mealType = value),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primaryColor : AppTheme.mutedText,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }
}
