import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../constants/app_config.dart';
import '../models/custom_food.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../models/nutrition_result.dart';
import '../services/nutrition_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/datetime_utils.dart';
import '../utils/input_validator.dart';
import '../utils/app_logger.dart';
import '../widgets/edit_food_dialog.dart';
import '../widgets/app_icon_bubble.dart';
import '../widgets/nutrition_source_badge.dart';
import '../widgets/tube_progress_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/organic_page.dart';

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
  String _selectedMeal = AppConfig.mealTypeBreakfast;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  NutritionResult? _lastNutritionResult;
  List<FoodItem> _recentFoods = [];
  List<CustomFood> _customFoods = [];
  StreamSubscription<List<CustomFood>>? _customFoodsSubscription;
  late final ValueNotifier<int> _scanRequestVersionNotifier;

  @override
  void initState() {
    super.initState();
    _scanRequestVersionNotifier = ValueNotifier<int>(widget.scanRequestVersion);
    _scanRequestVersionNotifier.addListener(_onScanRequestVersionChanged);
    _loadRecentFoods();
  }

  @override
  void didUpdateWidget(covariant TrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanRequestVersion != oldWidget.scanRequestVersion) {
      _scanRequestVersionNotifier.value = widget.scanRequestVersion;
    }
  }

  void _onScanRequestVersionChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scanFood();
    });
  }

  Future<void> _loadRecentFoods() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final fs = Provider.of<FirestoreService>(context, listen: false);
      final foods = await fs.getRecentUniqueFoods(user.uid);
      _customFoodsSubscription ??=
          fs.streamCustomFoods(user.uid).listen((customFoods) {
        if (!mounted) return;
        setState(() => _customFoods = customFoods);
      });
      if (mounted) {
        setState(() {
          _recentFoods = foods;
        });
      }
    }
  }

  Future<bool> _confirmRemoveFood(FoodItem food) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('ลบรายการอาหาร'),
            content: Text('ต้องการลบ "${food.name}" ออกจากบันทึกวันนี้ใช่ไหม'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('ลบ'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return false;

    final uid = authService.currentUser?.uid;
    if (uid == null || food.id.isEmpty) return false;

    try {
      await firestoreService.removeFood(uid, food.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบ ${food.name} เรียบร้อยแล้ว'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบรายการไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
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
    return DateTimeUtils.getCurrentMealType();
  }

  @override
  void dispose() {
    _customFoodsSubscription?.cancel();
    _scanRequestVersionNotifier.removeListener(_onScanRequestVersionChanged);
    _scanRequestVersionNotifier.dispose();
    _foodController.dispose();
    _calController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _addFood() async {
    final name = InputValidator.sanitizeForStorage(_foodController.text);
    final calText = _calController.text.trim();
    final cal = int.tryParse(calText);
    final protein = int.tryParse(_proteinController.text.trim()) ?? 0;
    final carbs = int.tryParse(_carbsController.text.trim()) ?? 0;
    final fat = int.tryParse(_fatController.text.trim()) ?? 0;

    final nameError = InputValidator.validateFoodName(name);
    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nameError),
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
            time: DateTimeUtils.now(),
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
    if (!NutritionService.isConfigured) {
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
        AppLogger.info('Analyzing image (${bytes.length} bytes)');
        final result = await NutritionService.analyzeImage(bytes);
        AppLogger.info('AI image analysis completed');

        if (mounted) {
          if (result != null) {
            setState(() {
              _lastNutritionResult = result;
              final detectedName = result.name.trim();
              _foodController.text = detectedName.isNotEmpty
                  ? detectedName
                  : (_foodController.text.trim().isNotEmpty
                      ? _foodController.text.trim()
                      : 'อาหารที่สแกน');
              _calController.text = result.calories.toString();
              _proteinController.text = result.protein.toString();
              _carbsController.text = result.carbs.toString();
              _fatController.text = result.fat.toString();
              _isAnalyzing = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'AI วิเคราะห์: ${_foodController.text} (${result.calories} kcal)',
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
      AppLogger.error('Error scanning food', e);
      if (mounted) {
        setState(() => _isAnalyzing = false);
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถวิเคราะห์รูปภาพได้: $errorMsg'),
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

    setState(() => _isAnalyzing = true);
    try {
      AppLogger.info('Looking up nutrition for: $name');
      final result = await NutritionService.lookupFood(name);
      AppLogger.info('Nutrition lookup completed: ${result?.source}');

      if (mounted) {
        if (result != null) {
          setState(() {
            _lastNutritionResult = result;
            if (result.name.isNotEmpty && result.name != name) {
              _foodController.text = result.name;
            }
            _calController.text = result.calories.toString();
            _proteinController.text = result.protein.toString();
            _carbsController.text = result.carbs.toString();
            _fatController.text = result.fat.toString();
            _isAnalyzing = false;
          });

          final sourceLabel = result.source == NutritionSource.database
              ? '📊 จากฐานข้อมูล'
              : '✨ ค่าประมาณ AI';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$sourceLabel: ${result.calories} kcal (${result.servingLabel})',
              ),
              backgroundColor: result.source == NutritionSource.database
                  ? const Color(0xFF16A34A)
                  : Colors.amber[700],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถระบุข้อมูลโภชนาการได้'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error estimating calories', e);
      if (mounted) {
        setState(() => _isAnalyzing = false);
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการคำนวณ: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrganicPage(
      child: Column(
        children: [
          const OrganicScreenTitle(
            title: 'Foodcal',
            subtitle: 'Daily Tracking',
          ),
          const SizedBox(height: 22),
          OrganicAppFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FoodGardenBanner(
                  title: 'บันทึกประจำวัน',
                  subtitle: 'อาหาร น้ำดื่ม และพลังงานวันนี้',
                  icon: LucideIcons.utensils,
                  compact: true,
                ),
                const SizedBox(height: AppTheme.sectionGap),
                Row(
                  children: [
                    Expanded(
                      child: _TrackingModeTile(
                        icon: LucideIcons.search,
                        title: 'พิมพ์ชื่ออาหาร',
                        subtitle: 'ค้นหาและให้ AI ประเมิน',
                        color: AppTheme.primaryColor,
                        onTap: () => FocusScope.of(context).requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TrackingModeTile(
                        icon: LucideIcons.camera,
                        title: 'สแกนจาน',
                        subtitle:
                            _isAnalyzing ? 'กำลังวิเคราะห์' : 'เปิดกล้องทันที',
                        color: AppTheme.accentColor,
                        onTap: _isAnalyzing ? null : _scanFood,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.sectionGap),
                GlassCard(
                  padding: const EdgeInsets.all(AppTheme.cardPadding),
                  opacity: 0.15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                AppIconBubble(
                                  color: AppTheme.primaryColor,
                                  size: 36,
                                  child: Icon(
                                    LucideIcons.utensils,
                                    color: AppTheme.primaryColor,
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'บันทึกอาหาร',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: AppTheme.ink),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(LucideIcons.camera, size: 18),
                            label: Text(_isAnalyzing ? 'วิเคราะห์...' : 'สแกน'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'กรอกเองหรือใช้ AI ช่วยประเมินค่าโภชนาการก็ได้',
                        style: TextStyle(
                            fontSize: AppTheme.body, color: AppTheme.mutedText),
                      ),
                      if (_lastNutritionResult != null) ...[
                        const SizedBox(height: 12),
                        NutritionSourceBadge(
                          source: _lastNutritionResult!.source,
                          servingLabel: _lastNutritionResult!.servingLabel,
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextField(
                        controller: _foodController,
                        decoration: InputDecoration(
                          hintText: 'ชื่ออาหาร (เช่น ข้าวมันไก่)',
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          suffixIcon: IconButton(
                            icon: const Icon(LucideIcons.sparkles,
                                color: Colors.amber, size: 20),
                            onPressed:
                                _isAnalyzing ? null : _estimateCaloriesText,
                          ),
                        ),
                      ),
                      if (_customFoods.isNotEmpty ||
                          _recentFoods.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'อาหารที่ใช้บ่อย & บันทึกไว้',
                          style: TextStyle(
                              fontSize: AppTheme.meta,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.mutedText),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            children: [
                              for (final food in _customFoods)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: ActionChip(
                                    label: Text(food.name),
                                    avatar: const Icon(LucideIcons.star,
                                        size: 14, color: AppTheme.warning),
                                    onPressed: () => _useCustomFood(food),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              for (final food in _recentFoods)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: ActionChip(
                                    label: Text(food.name),
                                    avatar: const Icon(LucideIcons.history,
                                        size: 14),
                                    onPressed: () => _useRecentFood(food),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'โภชนาการโดยประมาณ',
                        style: TextStyle(
                            fontSize: AppTheme.meta,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _calController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'แคลอรี่ (kcal)',
                          prefixIcon: Icon(LucideIcons.zap, size: 18),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _buildMacroField(
                                  _proteinController, 'โปรตีน (g)')),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _buildMacroField(
                                  _carbsController, 'คาร์บ (g)')),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _buildMacroField(
                                  _fatController, 'ไขมัน (g)')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'เลือกมื้ออาหาร',
                        style: TextStyle(
                            fontSize: AppTheme.meta,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedText),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            _buildMealChip('เช้า', AppConfig.mealTypeBreakfast,
                                LucideIcons.sunrise),
                            const SizedBox(width: 8),
                            _buildMealChip('กลางวัน', AppConfig.mealTypeLunch,
                                LucideIcons.sun),
                            const SizedBox(width: 8),
                            _buildMealChip('เย็น', AppConfig.mealTypeDinner,
                                LucideIcons.sunset),
                            const SizedBox(width: 8),
                            _buildMealChip('ว่าง', AppConfig.mealTypeSnack,
                                LucideIcons.coffee),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        text: 'เพิ่มรายการอาหาร',
                        icon: LucideIcons.plusCircle,
                        onPressed: _addFood,
                      ),
                      if (widget.log != null &&
                          widget.log!.foods.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text(
                              'มื้อวันนี้',
                              style: TextStyle(
                                  fontSize: AppTheme.title,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink),
                            ),
                            const Spacer(),
                            Text(
                              '${widget.log!.foods.length} รายการ',
                              style: const TextStyle(
                                  fontSize: AppTheme.meta,
                                  color: AppTheme.mutedText,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...widget.log!.foods.reversed.take(5).map(
                              (food) => Dismissible(
                                key: Key(food.id.isNotEmpty
                                    ? food.id
                                    : food.name + food.time.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.error.withValues(alpha: 0.8),
                                    borderRadius: AppTheme.innerRadius,
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(LucideIcons.trash2,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (_) => _confirmRemoveFood(food),
                                child: _FoodItemTile(food: food),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GlassCard(
                  padding: const EdgeInsets.all(AppTheme.cardPadding),
                  opacity: 0.12,
                  borderColor: AppTheme.waterColor.withValues(alpha: 0.2),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const AppIconBubble(
                                  color: AppTheme.waterColor,
                                  size: 36,
                                  child: Icon(
                                    LucideIcons.droplet,
                                    color: AppTheme.waterColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'ดื่มน้ำ (เป้าหมาย ${widget.profile.targetWaterGlasses} แก้ว)',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: AppTheme.ink),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${widget.log?.waterGlasses ?? 0}',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.waterColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TubeProgressBar(
                        progress: (widget.profile.targetWaterGlasses > 0
                                ? (widget.log?.waterGlasses ?? 0) /
                                    widget.profile.targetWaterGlasses
                                : 0.0)
                            .clamp(0.0, 1.0),
                        colors: const [
                          AppTheme.secondaryColor,
                          AppTheme.waterColor
                        ],
                        height: 12,
                        borderRadius: 999,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _WaterActionBtn(
                            icon: LucideIcons.minus,
                            onTap: () => _updateWater(-1),
                            color: Colors.blueGrey,
                            isOutline: true,
                          ),
                          _WaterActionBtn(
                            icon: LucideIcons.plus,
                            label: '1 แก้ว',
                            onTap: () => _updateWater(1),
                            color: AppTheme.waterColor,
                          ),
                          _WaterActionBtn(
                            icon: LucideIcons.plus,
                            label: '500 มล',
                            onTap: () => _updateWater(2),
                            color: AppTheme.waterColor,
                          ),
                          _WaterActionBtn(
                            icon: LucideIcons.plus,
                            label: '1.5 ลิตร',
                            onTap: () => _updateWater(6),
                            color: AppTheme.waterColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealChip(String label, String value, IconData icon) {
    final selected = _selectedMeal == value;
    final mealColor = _mealColor(value);
    return GestureDetector(
      onTap: () => setState(() => _selectedMeal = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? mealColor : mealColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? mealColor : mealColor.withValues(alpha: 0.2),
          ),
          boxShadow: selected ? AppTheme.softShadow(mealColor) : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : mealColor, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : mealColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _mealColor(String value) {
    if (value == AppConfig.mealTypeBreakfast) return AppTheme.warmOrange;
    if (value == AppConfig.mealTypeLunch) return AppTheme.warning;
    if (value == AppConfig.mealTypeDinner) return AppTheme.accentColor;
    return AppTheme.mutedText;
  }

  Widget _buildMacroField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }
}

class _TrackingModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _TrackingModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        opacity: 0.13,
        padding: const EdgeInsets.all(14),
        borderColor: color.withValues(alpha: 0.18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconBubble(
              color: color,
              size: 38,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.mutedText,
                fontSize: 11,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodItemTile extends StatelessWidget {
  final FoodItem food;

  const _FoodItemTile({required this.food});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final edited = await EditFoodDialog.show(context, existing: food);
        if (edited != null && context.mounted) {
          final uid =
              Provider.of<AuthService>(context, listen: false).currentUser?.uid;
          if (uid != null && edited.id.isNotEmpty) {
            await Provider.of<FirestoreService>(context, listen: false)
                .updateFoodItem(uid, edited);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          opacity: 0.1,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.utensils,
                    color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${food.mealType} · P ${food.protein}g / C ${food.carbs}g / F ${food.fat}g',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.mutedText,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${food.calories}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor),
                  ),
                  const Text(
                    'kcal',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaterActionBtn extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final Color color;
  final bool isOutline;

  const _WaterActionBtn({
    required this.icon,
    this.label,
    required this.onTap,
    required this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: AppTheme.innerRadius,
          border: isOutline
              ? Border.all(color: color.withValues(alpha: 0.3), width: 2)
              : null,
          boxShadow: isOutline ? null : AppTheme.softShadow(color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isOutline ? color : Colors.white, size: 18),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: TextStyle(
                  color: isOutline ? color : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
