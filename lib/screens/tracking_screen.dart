import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/custom_food.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/edit_food_dialog.dart';
import '../widgets/tube_progress_bar.dart';

class TrackingScreen extends StatefulWidget {
  final DailyLog? log;
  final UserProfile profile;
  final int scanRequestVersion;

  const TrackingScreen({
    super.key,
    required this.log,
    required this.profile,
    this.scanRequestVersion = 0,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const int _maxCalories = 5000;
  static const int _maxMacro = 500;

  final _foodController = TextEditingController();
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  String _selectedMeal = 'Breakfast';
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  List<FoodItem> _recentFoods = [];
  List<CustomFood> _customFoods = [];
  int _lastHandledScanRequestVersion = 0;

  @override
  void initState() {
    super.initState();
    _lastHandledScanRequestVersion = widget.scanRequestVersion;
    _loadRecentFoods();
  }

  @override
  void didUpdateWidget(covariant TrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanRequestVersion != oldWidget.scanRequestVersion &&
        widget.scanRequestVersion != _lastHandledScanRequestVersion) {
      _lastHandledScanRequestVersion = widget.scanRequestVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scanFood();
        }
      });
    }
  }

  Future<void> _loadRecentFoods() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final fs = Provider.of<FirestoreService>(context, listen: false);
      final foods = await fs.getRecentUniqueFoods(user.uid);
      final custom = await fs.streamCustomFoods(user.uid).first;
      if (mounted) {
        setState(() {
          _recentFoods = foods;
          _customFoods = custom;
        });
      }
    }
  }

  void _useCustomFood(CustomFood food) {
    setState(() {
      _foodController.text = food.name;
      _calController.text = food.calories.toString();
      _proteinController.text = food.protein.toString();
      _carbsController.text = food.carbs.toString();
      _fatController.text = food.fat.toString();
      _selectedMeal = _getCurrentMealType();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เลือก: ${food.name} เรียบร้อย'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _useRecentFood(FoodItem food) {
    setState(() {
      _foodController.text = food.name;
      _calController.text = food.calories.toString();
      _proteinController.text = food.protein.toString();
      _carbsController.text = food.carbs.toString();
      _fatController.text = food.fat.toString();
      _selectedMeal = _getCurrentMealType();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เลือก: ${food.name} เรียบร้อย'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getCurrentMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 20) return 'Dinner';
    return 'Snack';
  }

  @override
  void dispose() {
    _foodController.dispose();
    _calController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _addFood() async {
    final name = _foodController.text.trim();
    final calText = _calController.text.trim();
    final cal = int.tryParse(calText);
    final protein = int.tryParse(_proteinController.text.trim()) ?? 0;
    final carbs = int.tryParse(_carbsController.text.trim()) ?? 0;
    final fat = int.tryParse(_fatController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่ออาหาร'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (calText.isEmpty || cal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกจำนวนแคลอรี่ให้ถูกต้อง'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if ([cal, protein, carbs, fat].any((value) => value < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกค่าที่ไม่ติดลบ'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (cal > _maxCalories ||
        protein > _maxMacro ||
        carbs > _maxMacro ||
        fat > _maxMacro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ค่าที่กรอกสูงเกินช่วงที่ระบบยอมรับ'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      try {
        final messenger = ScaffoldMessenger.of(context);
        final focusScope = FocusScope.of(context);
        await Provider.of<FirestoreService>(context, listen: false).addFood(
          user.uid,
          FoodItem(
            name: name,
            calories: cal,
            protein: protein,
            carbs: carbs,
            fat: fat,
            time: DateTime.now(),
            mealType: _selectedMeal,
          ),
        );
        _foodController.clear();
        _calController.clear();
        _proteinController.clear();
        _carbsController.clear();
        _fatController.clear();
        focusScope.unfocus();

        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateWater(int delta) async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      await Provider.of<FirestoreService>(context, listen: false)
          .updateWater(user.uid, delta);
      if (mounted) {
        final label = delta > 0 ? '+$delta แก้ว' : '$delta แก้ว';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกน้ำ $label เรียบร้อย'),
            backgroundColor: AppTheme.waterColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _scanFood() async {
    if (!AIService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ฟีเจอร์ AI ยังไม่พร้อมใช้งาน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        imageQuality: 35,
      );

      if (photo != null) {
        setState(() => _isAnalyzing = true);

        final bytes = await photo.readAsBytes();
        debugPrint('Analyzing image (${bytes.length} bytes)...');
        final result = await AIService.analyzeFoodImage(bytes);
        debugPrint('AI Result: $result');

        if (mounted) {
          if (result != null && result.containsKey('name')) {
            setState(() {
              _foodController.text = result['name'] ?? '';
              _calController.text = (result['calories'] ?? '').toString();
              _proteinController.text = (result['protein'] ?? '').toString();
              _carbsController.text = (result['carbs'] ?? '').toString();
              _fatController.text = (result['fat'] ?? '').toString();
              _isAnalyzing = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'AI วิเคราะห์: ${result['name']} (${result['calories']} kcal)',
                ),
                backgroundColor: Colors.blueAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            setState(() => _isAnalyzing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'AI ไม่สามารถระบุอาหารได้ กรุณาลองใหม่อีกครั้ง',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning food: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถวิเคราะห์รูปภาพได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _estimateCaloriesText() async {
    final name = _foodController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาพิมพ์ชื่ออาหารก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!AIService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ฟีเจอร์ AI ยังไม่พร้อมใช้งาน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      debugPrint('Estimating calories for: $name');
      final result = await AIService.estimateCalories(name);
      debugPrint('AI Translation Result: $result');

      if (mounted) {
        if (result != null) {
          setState(() {
            _calController.text = (result['calories'] ?? '').toString();
            _proteinController.text = (result['protein'] ?? '').toString();
            _carbsController.text = (result['carbs'] ?? '').toString();
            _fatController.text = (result['fat'] ?? '').toString();
            _isAnalyzing = false;
          });
        } else {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI ไม่สามารถระบุข้อมูลพลังงานได้'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error estimating calories: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการคำนวณ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = AppTheme.isCompactWidth(screenWidth);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppTheme.maxContentWidth(screenWidth),
        ),
        child: SingleChildScrollView(
          padding: AppTheme.pageInsetsForWidth(screenWidth, bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppTheme.sectionGap),
              Container(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                decoration: AppTheme.elevatedCard(
                  color: Colors.white,
                  borderColor: const Color(0xFFE4EEFB),
                  boxShadow: AppTheme.softShadow(AppTheme.primaryColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(LucideIcons.utensils,
                                  color: Colors.blue[400], size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'บันทึกอาหาร',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isAnalyzing ? null : _scanFood,
                          icon: _isAnalyzing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.camera, size: 18),
                          label: Text(_isAnalyzing ? 'วิเคราะห์...' : 'สแกน'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[600],
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'กรอกเองหรือใช้ AI ช่วยประเมินค่าโภชนาการก็ได้',
                      style: TextStyle(
                          fontSize: AppTheme.body, color: AppTheme.mutedText),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _foodController,
                      decoration: InputDecoration(
                        hintText: 'ชื่ออาหาร (เช่น ข้าวมันไก่)',
                        filled: true,
                        fillColor: AppTheme.macroBg(AppTheme.calorieColor),
                        border: const OutlineInputBorder(
                          borderRadius: AppTheme.innerRadius,
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(LucideIcons.sparkles,
                              color: Colors.amber, size: 20),
                          onPressed: _estimateCaloriesText,
                        ),
                      ),
                    ),
                    if (_customFoods.isNotEmpty || _recentFoods.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'อาหารที่ใช้บ่อย & บันทึกไว้',
                        style: TextStyle(
                            fontSize: AppTheme.meta,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final food in _customFoods)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  label: Text(food.name, style: const TextStyle(fontSize: 11)),
                                  avatar: const Icon(LucideIcons.star, size: 14, color: AppTheme.warning),
                                  onPressed: () => _useCustomFood(food),
                                  backgroundColor: AppTheme.warning.withValues(alpha: 0.1),
                                  side: BorderSide(color: AppTheme.warning.withValues(alpha: 0.3)),
                                  labelStyle: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.bold),
                                ),
                              ),
                            for (final food in _recentFoods)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ActionChip(
                                  label: Text(food.name, style: const TextStyle(fontSize: 11)),
                                  avatar: const Icon(LucideIcons.history, size: 14),
                                  onPressed: () => _useRecentFood(food),
                                  backgroundColor: AppTheme.pageTintStrong,
                                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.12)),
                                  labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'โภชนาการโดยประมาณ',
                      style: TextStyle(
                          fontSize: AppTheme.meta,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedText),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _calController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'แคลอรี่ (kcal)',
                              filled: true,
                              fillColor: Color(0x1A1F6FEB),
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.innerRadius,
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'เลือกมื้ออาหาร',
                      style: TextStyle(
                          fontSize: AppTheme.meta,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedText),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildMealChip(
                            'เช้า', 'Breakfast', LucideIcons.sunrise),
                        _buildMealChip('กลางวัน', 'Lunch', LucideIcons.sun),
                        _buildMealChip('เย็น', 'Dinner', LucideIcons.sunset),
                        _buildMealChip('ว่าง', 'Snack', LucideIcons.coffee),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildMacroField(
                          _proteinController,
                          'โปรตีน (g)',
                          compact: isCompact,
                        ),
                        _buildMacroField(
                          _carbsController,
                          'คาร์บ (g)',
                          compact: isCompact,
                        ),
                        _buildMacroField(
                          _fatController,
                          'ไขมัน (g)',
                          compact: isCompact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addFood,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize:
                              const Size.fromHeight(AppTheme.buttonHeight),
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppTheme.innerRadius),
                        ),
                        child: const Text(
                          'เพิ่มรายการอาหาร',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (widget.log != null && widget.log!.foods.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'มื้อวันนี้',
                        style: TextStyle(
                            fontSize: AppTheme.title,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'รายการล่าสุดที่บันทึกไว้ในวันนี้',
                        style: TextStyle(
                            fontSize: AppTheme.body, color: AppTheme.mutedText),
                      ),
                      const SizedBox(height: 14),
                      ...widget.log!.foods.reversed.take(5).map(
                            (food) => Dismissible(
                              key: Key(food.id.isNotEmpty ? food.id : food.name + food.time.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: AppTheme.innerRadius,
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(LucideIcons.trash2, color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                final uid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
                                if (uid != null && food.id.isNotEmpty) {
                                  await Provider.of<FirestoreService>(context, listen: false).removeFood(uid, food.id);
                                }
                              },
                              child: GestureDetector(
                                onTap: () async {
                                  final edited = await EditFoodDialog.show(context, existing: food);
                                  if (edited != null && context.mounted) {
                                    final uid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
                                    if (uid != null && edited.id.isNotEmpty) {
                                      await Provider.of<FirestoreService>(context, listen: false).updateFoodItem(uid, edited);
                                    }
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.pageTint,
                                    borderRadius: AppTheme.innerRadius,
                                    border:
                                        Border.all(color: const Color(0xFFDCE8FA)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(LucideIcons.utensils,
                                            color: AppTheme.primaryColor, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(food.name,
                                                style: const TextStyle(
                                                    fontSize: AppTheme.body,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.ink)),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${food.mealType} • P ${food.protein} / C ${food.carbs} / F ${food.fat}',
                                              style: const TextStyle(
                                                  fontSize: AppTheme.meta,
                                                  color: AppTheme.mutedText),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text('${food.calories} kcal',
                                          style: const TextStyle(
                                              fontSize: AppTheme.body,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryColor)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                decoration: AppTheme.elevatedCard(
                  color: Colors.white,
                  borderColor: AppTheme.waterColor.withValues(alpha: 0.12),
                  boxShadow: AppTheme.softShadow(AppTheme.waterColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.droplet,
                                color: AppTheme.waterColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ดื่มน้ำ (เป้าหมาย ${widget.profile.targetWaterGlasses} แก้ว)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppTheme.title,
                                color: AppTheme.ink,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.log?.waterGlasses ?? 0}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.waterColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'อัปเดตเป็นช่วง ๆ เพื่อให้ dashboard สรุปแม่นขึ้น',
                        style: TextStyle(
                            fontSize: AppTheme.body, color: AppTheme.mutedText),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TubeProgressBar(
                      progress: (widget.profile.targetWaterGlasses > 0
                              ? (widget.log?.waterGlasses ?? 0) /
                                  widget.profile.targetWaterGlasses
                              : 0.0)
                          .clamp(0.0, 1.0),
                      colors: const [AppTheme.waterColor, AppTheme.waterColor],
                      height: 16,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildWaterBtn(
                          '-',
                          Colors.blue[50]!,
                          Colors.blue[600]!,
                          () => _updateWater(-1),
                          label: '1',
                        ),
                        _buildWaterBtn(
                          '+',
                          Colors.blue[600]!,
                          Colors.white,
                          () => _updateWater(1),
                          label: 'แก้ว',
                        ),
                        _buildWaterBtn(
                          '+',
                          Colors.blue[600]!,
                          Colors.white,
                          () => _updateWater(2),
                          label: '500 มล',
                        ),
                        _buildWaterBtn(
                          '+',
                          Colors.blue[600]!,
                          Colors.white,
                          () => _updateWater(6),
                          label: '1.5 ลิตร',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.tintedCard(AppTheme.primaryColor),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'บันทึกประจำวัน',
            style: TextStyle(
                fontSize: AppTheme.largeTitle,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink),
          ),
          SizedBox(height: 6),
          Text(
            'แยกเป็นบล็อกชัดเจนเพื่อให้เพิ่มอาหาร น้ำ และติดตามรายการของวันนี้ได้ง่ายขึ้น',
            style: TextStyle(
                fontSize: AppTheme.body,
                color: AppTheme.mutedText,
                height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMealChip(String label, String value, IconData icon) {
    final selected = _selectedMeal == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedMeal = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.blue[600] : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.blueGrey, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.blueGrey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroField(
    TextEditingController controller,
    String hint, {
    required bool compact,
  }) {
    return SizedBox(
      width: compact ? 148 : 140,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: AppTheme.macroBg(AppTheme.calorieColor),
          border: const OutlineInputBorder(
            borderRadius: AppTheme.innerRadius,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildWaterBtn(
    String prefix,
    Color bg,
    Color text,
    VoidCallback onTap, {
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppTheme.cardRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                prefix,
                style: TextStyle(
                    color: text, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                      color: text, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
