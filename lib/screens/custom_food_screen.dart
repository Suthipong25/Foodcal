import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app_theme.dart';
import '../models/custom_food.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class CustomFoodScreen extends StatefulWidget {
  const CustomFoodScreen({super.key});

  @override
  State<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends State<CustomFoodScreen> {


  String? get _uid =>
      Provider.of<AuthService>(context, listen: false).currentUser?.uid;

  Future<void> _openForm({CustomFood? existing}) async {
    final result = await showModalBottomSheet<CustomFood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomFoodForm(existing: existing),
    );
    if (result == null || !mounted) return;
    final uid = _uid;
    if (uid == null) return;
    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .saveCustomFood(uid, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('บันทึกเรียบร้อย ✓'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _delete(String foodId) async {
    final uid = _uid;
    if (uid == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบรายการนี้?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await Provider.of<FirestoreService>(context, listen: false)
        .deleteCustomFood(uid, foodId);
  }

  Future<void> _toggleFavorite(CustomFood food) async {
    final uid = _uid;
    if (uid == null) return;
    await Provider.of<FirestoreService>(context, listen: false)
        .toggleFavorite(uid, food.id, isFavorite: !food.isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('อาหารที่บันทึกไว้',
            style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppTheme.primaryColor),
            onPressed: () => _openForm(),
            tooltip: 'เพิ่มอาหารใหม่',
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
          : StreamBuilder<List<CustomFood>>(
              stream: Provider.of<FirestoreService>(context, listen: false)
                  .streamCustomFoods(uid),
              builder: (context, snap) {
                final foods = snap.data ?? [];
                if (foods.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.bookMarked,
                            size: 64, color: AppTheme.mutedText),
                        const SizedBox(height: 16),
                        const Text('ยังไม่มีอาหารที่บันทึกไว้',
                            style: TextStyle(
                                color: AppTheme.mutedText, fontSize: AppTheme.title)),
                        const SizedBox(height: 8),
                        const Text('กด + เพื่อเพิ่มรายการอาหารที่ใช้บ่อย',
                            style: TextStyle(
                                color: AppTheme.mutedText, fontSize: AppTheme.body)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(LucideIcons.plus),
                          label: const Text('เพิ่มอาหาร'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: AppTheme.maxContentWidth(screenWidth)),
                    child: ListView.builder(
                      padding: AppTheme.pageInsetsForWidth(screenWidth, bottom: 32),
                      itemCount: foods.length,
                      itemBuilder: (ctx, i) => _buildTile(foods[i]),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildTile(CustomFood food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.elevatedCard(
        color: Colors.white,
        borderColor: food.isFavorite
            ? AppTheme.warning.withValues(alpha: 0.25)
            : const Color(0xFFE3ECFA),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.utensils, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(food.name,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
        subtitle: Text(
          '${food.calories} kcal · P${food.protein} C${food.carbs} F${food.fat}  '
          '(${food.servingSize.toStringAsFixed(0)} ${food.servingUnit}/serving)',
          style: const TextStyle(fontSize: AppTheme.meta, color: AppTheme.mutedText),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                food.isFavorite ? LucideIcons.star : LucideIcons.star,
                color: food.isFavorite ? AppTheme.warning : AppTheme.mutedText,
                size: 20,
              ),
              onPressed: () => _toggleFavorite(food),
            ),
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 18, color: AppTheme.mutedText),
              onPressed: () => _openForm(existing: food),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.mutedText),
              onPressed: () => _delete(food.id),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form ──────────────────────────────────────────────────────────────────────

class _CustomFoodForm extends StatefulWidget {
  final CustomFood? existing;

  const _CustomFoodForm({this.existing});

  @override
  State<_CustomFoodForm> createState() => _CustomFoodFormState();
}

class _CustomFoodFormState extends State<_CustomFoodForm> {
  static const _uuid = Uuid();

  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _servingSizeCtrl = TextEditingController();
  final _servingUnitCtrl = TextEditingController();
  bool _isFavorite = false;

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
      _servingSizeCtrl.text = f.servingSize.toStringAsFixed(0);
      _servingUnitCtrl.text = f.servingUnit;
      _isFavorite = f.isFavorite;
    } else {
      _servingSizeCtrl.text = '100';
      _servingUnitCtrl.text = 'g';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _servingSizeCtrl.dispose();
    _servingUnitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final cal = int.tryParse(_calCtrl.text.trim());
    final protein = int.tryParse(_proteinCtrl.text.trim()) ?? 0;
    final carbs = int.tryParse(_carbsCtrl.text.trim()) ?? 0;
    final fat = int.tryParse(_fatCtrl.text.trim()) ?? 0;
    final servingSize = double.tryParse(_servingSizeCtrl.text.trim()) ?? 100;
    final servingUnit = _servingUnitCtrl.text.trim().isEmpty ? 'g' : _servingUnitCtrl.text.trim();

    if (name.isEmpty || cal == null || cal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณากรอกชื่อและแคลอรี่ให้ถูกต้อง'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final food = CustomFood(
      id: widget.existing?.id ?? _uuid.v4(),
      name: name,
      calories: cal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      servingSize: servingSize,
      servingUnit: servingUnit,
      isFavorite: _isFavorite,
    );
    Navigator.pop(context, food);
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
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEdit ? 'แก้ไขอาหาร' : 'เพิ่มอาหารใหม่',
                  style: const TextStyle(
                      fontSize: AppTheme.title, fontWeight: FontWeight.w800, color: AppTheme.ink),
                ),
                const SizedBox(height: 16),
                _field(_nameCtrl, 'ชื่ออาหาร *', TextInputType.text),
                const SizedBox(height: 10),
                _field(_calCtrl, 'แคลอรี่ (kcal) *', TextInputType.number),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_proteinCtrl, 'โปรตีน (g)', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_carbsCtrl, 'คาร์บ (g)', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_fatCtrl, 'ไขมัน (g)', TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: _field(_servingSizeCtrl, 'Serving size', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _field(_servingUnitCtrl, 'หน่วย (g/ml)', TextInputType.text)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _isFavorite,
                      onChanged: (v) => setState(() => _isFavorite = v ?? false),
                      activeColor: AppTheme.warning,
                    ),
                    const Text('เพิ่มในรายการโปรด ⭐'),
                  ],
                ),
                const SizedBox(height: 16),
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
                    child: Text(_isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มรายการ',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
            borderRadius: AppTheme.innerRadius, borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
