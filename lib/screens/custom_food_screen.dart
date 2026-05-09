import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../app_theme.dart';
import '../models/custom_food.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/animated_page_wrapper.dart';
import '../widgets/glass_card.dart';

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

    return AnimatedPageWrapper(
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('อาหารที่บันทึกไว้',
                style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w900)),
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppTheme.primaryColor),
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
          Expanded(
            child: uid == null
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
                                      color: AppTheme.mutedText, fontSize: AppTheme.title, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text('กด + เพื่อเพิ่มรายการอาหารที่ใช้บ่อย',
                                  style: TextStyle(
                                      color: AppTheme.mutedText, fontSize: AppTheme.body)),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _openForm(),
                                icon: const Icon(LucideIcons.plus),
                                label: const Text('เริ่มบันทึกอาหารแรก', style: TextStyle(fontWeight: FontWeight.w800)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            padding: AppTheme.pageInsetsForWidth(screenWidth, bottom: 80),
                            itemCount: foods.length,
                            itemBuilder: (ctx, i) => _buildTile(foods[i]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(CustomFood food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        opacity: 0.1,
        borderColor: food.isFavorite
            ? AppTheme.warning.withValues(alpha: 0.3)
            : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.utensils, color: AppTheme.primaryColor, size: 20),
          ),
          title: Text(food.name,
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.ink, fontSize: 15)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${food.calories} kcal · P${food.protein} C${food.carbs} F${food.fat}',
                style: const TextStyle(fontSize: 12, color: AppTheme.mutedText, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'ต่อ ${food.servingSize.toStringAsFixed(0)} ${food.servingUnit}',
                style: const TextStyle(fontSize: 10, color: AppTheme.mutedText, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  LucideIcons.star,
                  color: food.isFavorite ? AppTheme.warning : AppTheme.mutedText.withValues(alpha: 0.4),
                  size: 20,
                ),
                onPressed: () => _toggleFavorite(food),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(LucideIcons.pencil, size: 18, color: AppTheme.mutedText),
                onPressed: () => _openForm(existing: food),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.mutedText),
                onPressed: () => _delete(food.id),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
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
                      child: const Icon(LucideIcons.edit3, color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _isEdit ? 'แก้ไขรายการอาหาร' : 'บันทึกอาหารโปรด',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _field(_nameCtrl, 'ชื่ออาหาร (เช่น สลัดอกไก่)', TextInputType.text, icon: LucideIcons.tag),
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
                const Text('ขนาดต่อหนึ่งหน่วยบริโภค', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.mutedText, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: _field(_servingSizeCtrl, 'ปริมาณที่กิน', TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _field(_servingUnitCtrl, 'หน่วย (กรัม/มล.)', TextInputType.text)),
                  ],
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => setState(() => _isFavorite = !_isFavorite),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isFavorite,
                          onChanged: (v) => setState(() => _isFavorite = v ?? false),
                          activeColor: AppTheme.warning,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        const Text('บันทึกเป็นรายการโปรด ⭐', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                    child: Text(_isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มรายการนี้',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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
}
