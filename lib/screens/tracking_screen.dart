
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';
import '../models/user_profile.dart'; 
import '../models/daily_log.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import 'dart:convert';
import '../widgets/tube_progress_bar.dart';
import '../app_theme.dart';

class TrackingScreen extends StatefulWidget {
  final DailyLog? log;
  final UserProfile profile;
  
  const TrackingScreen({Key? key, required this.log, required this.profile}) : super(key: key);

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _foodController = TextEditingController();
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  String _selectedMeal = 'Breakfast'; // Default to Breakfast
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  List<FoodItem> _recentFoods = [];

  @override
  void initState() {
    super.initState();
    _loadRecentFoods();
  }

  Future<void> _loadRecentFoods() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final foods = await Provider.of<FirestoreService>(context, listen: false).getRecentUniqueFoods(user.uid);
      if (mounted) setState(() => _recentFoods = foods);
    }
  }

  void _useRecentFood(FoodItem food) {
    setState(() {
      _foodController.text = food.name;
      _calController.text = food.calories.toString();
      _proteinController.text = food.protein.toString();
      _carbsController.text = food.carbs.toString();
      _fatController.text = food.fat.toString();
      _selectedMeal = _getCurrentMealType(); // Update to current meal type naturally
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เลือก: ${food.name} เรียบร้อย'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      )
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
        )
      );
      return;
    }

    if (calText.isEmpty || cal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกจำนวนแคลอรี่ให้ถูกต้อง'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }
    
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      try {
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
        FocusScope.of(context).unfocus(); // Close keyboard
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกข้อมูลเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            )
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red)
          );
        }
      }
    }
  }

  Future<void> _updateWater(int delta) async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      await Provider.of<FirestoreService>(context, listen: false).updateWater(
        user.uid,
        delta,
      );
    }
  }

  Future<void> _scanFood() async {
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
                content: Text('AI วิเคราะห์: ${result['name']} (${result['calories']} kcal)'),
                backgroundColor: Colors.blueAccent,
                behavior: SnackBarBehavior.floating,
              )
            );
          } else {
            setState(() => _isAnalyzing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI ไม่สามารถระบุอาหารได้ กรุณาลองใหม่อีกครั้ง'),
                backgroundColor: Colors.orange,
              )
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning food: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถวิเคราะห์รูปภาพได้: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _estimateCaloriesText() async {
    final name = _foodController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาพิมพ์ชื่ออาหารก่อน'), backgroundColor: Colors.orange)
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
            const SnackBar(content: Text('AI ไม่สามารถระบุข้อมูลพลังงานได้'), backgroundColor: Colors.orange)
          );
        }
      }
    } catch (e) {
      debugPrint('Error estimating calories: $e');
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการคำนวณ: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Food Entry Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.blue[50]!),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))
              ],
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
                          Icon(LucideIcons.utensils, color: Colors.blue[400], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('บันทึกอาหาร', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: _isAnalyzing ? null : _scanFood,
                      icon: _isAnalyzing 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.camera, size: 18),
                      label: Text(_isAnalyzing ? 'วิเคราะห์...' : 'สแกน'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _foodController,
                  decoration: InputDecoration(
                    hintText: 'ชื่ออาหาร (เช่น ข้าวมันไก่)',
                    filled: true, fillColor: AppTheme.macroBg(AppTheme.calorieColor),
                    border: OutlineInputBorder(borderRadius: AppTheme.innerRadius, borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.sparkles, color: Colors.amber, size: 20),
                      onPressed: _estimateCaloriesText,
                    ),
                  ),
                ),
                if (_recentFoods.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('อาหารที่จดบ่อย', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentFoods.length,
                      itemBuilder: (context, index) {
                        final food = _recentFoods[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(food.name, style: const TextStyle(fontSize: 11)),
                            avatar: const Icon(LucideIcons.history, size: 14),
                            onPressed: () => _useRecentFood(food),
                            backgroundColor: Colors.blue[50],
                            side: BorderSide(color: Colors.blue[100]!),
                            labelStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _calController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'แคลอรี่ (kcal)',
                          filled: true, fillColor: AppTheme.macroBg(AppTheme.calorieColor),
                          border: OutlineInputBorder(borderRadius: AppTheme.innerRadius, borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Meal Selector
                const Text('เลือกมื้ออาหาร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMealChip('เช้า', 'Breakfast', LucideIcons.sunrise),
                    _buildMealChip('กลางวัน', 'Lunch', LucideIcons.sun),
                    _buildMealChip('เย็น', 'Dinner', LucideIcons.sunset),
                    _buildMealChip('ว่าง', 'Snack', LucideIcons.coffee),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                   children: [
                     _buildMacroField(_proteinController, 'โปรตีน(g)'),
                     const SizedBox(width: 8),
                     _buildMacroField(_carbsController, 'คาร์บ(g)'),
                     const SizedBox(width: 8),
                     _buildMacroField(_fatController, 'ไขมัน(g)'),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: AppTheme.innerRadius),
                    ),
                    child: const Text('เพิ่มรายการอาหาร', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Food List Grouped by Meal
                if (widget.log != null && widget.log!.foods.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  ...['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((meal) {
                    final mealFoods = widget.log!.foods.where((f) => f.mealType == meal).toList();
                    if (mealFoods.isEmpty) return const SizedBox();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(_getMealLabel(meal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        ),
                        ...mealFoods.reversed.map((food) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.blue[50]!))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(food.name, style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                  Text('${food.calories} kcal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'P: ${food.protein}g | C: ${food.carbs}g | F: ${food.fat}g',
                                style: TextStyle(fontSize: 10, color: Colors.blueGrey[300]),
                              ),
                            ],
                          ),
                        )).toList(),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                ] else
                   Center(child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text('ยังไม่มีรายการอาหารวันนี้', style: TextStyle(color: Colors.blueGrey[200])),
                   )),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Water Tracking Card
          // Water Tracking Card
          Container(
             padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.blue[50]!),
              boxShadow: [
                BoxShadow(color: Colors.blue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                         const Icon(LucideIcons.droplet, color: AppTheme.waterColor, size: 20),
                         const SizedBox(width: 8),
                         Text('ดื่มน้ำ (เป้าหมาย ${widget.profile.targetWaterGlasses} แก้ว)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey[800])),
                      ],
                    ),
                    Text('${widget.log?.waterGlasses ?? 0}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.waterColor)),
                  ],
                ),
                const SizedBox(height: 20),
                // Water Progress Bar (Tube style)
                TubeProgressBar(
                  progress: (widget.profile.targetWaterGlasses > 0 
                    ? (widget.log?.waterGlasses ?? 0) / widget.profile.targetWaterGlasses 
                    : 0.0).clamp(0.0, 1.0),
                  colors: const [AppTheme.waterColor, AppTheme.waterColor],
                  height: 16,
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWaterBtn('-', Colors.blue[50]!, Colors.blue[600]!, () => _updateWater(-1), label: '1'),
                      const SizedBox(width: 12),
                      _buildWaterBtn('+', Colors.blue[600]!, Colors.white, () => _updateWater(1), label: 'แก้ว'),
                      const SizedBox(width: 12),
                      _buildWaterBtn('+', Colors.blue[600]!, Colors.white, () => _updateWater(2), label: '500มล'),
                      const SizedBox(width: 12),
                      _buildWaterBtn('+', Colors.blue[600]!, Colors.white, () => _updateWater(6), label: '1.5ลิตร'),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildMealChip(String label, String value, IconData icon) {
    bool selected = _selectedMeal == value;
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
            Icon(icon, color: selected ? Colors.white : Colors.blueGrey, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              color: selected ? Colors.white : Colors.blueGrey, 
              fontSize: 10, 
              fontWeight: FontWeight.bold
            )),
          ],
        ),
      ),
    );
  }

  String _getMealLabel(String meal) {
    switch (meal) {
      case 'Breakfast': return 'มื้อเช้า';
      case 'Lunch': return 'มื้อกลางวัน';
      case 'Dinner': return 'มื้อเย็น';
      case 'Snack': return 'มื้อว่าง';
      default: return 'อื่นๆ';
    }
  }

  Widget _buildMacroField(TextEditingController controller, String hint) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true, fillColor: AppTheme.macroBg(AppTheme.calorieColor),
          border: OutlineInputBorder(borderRadius: AppTheme.innerRadius, borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildWaterBtn(String prefix, Color bg, Color text, VoidCallback onTap, {required String label}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppTheme.cardRadius,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(prefix, style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
