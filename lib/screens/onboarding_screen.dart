import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../constants/app_config.dart';
import '../constants/enums.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import '../utils/datetime_utils.dart';
import '../utils/health_profile_stats.dart';
import '../utils/app_logger.dart';

import '../widgets/animated_page_wrapper.dart';
import '../widgets/decorative_elements.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 1;
  final TextEditingController _nameController = TextEditingController();
  String gender = Gender.male.value;
  int birthMonth = 1;
  int birthYear = 2000;
  double height = 170.0;
  double weight = 65.0;
  double targetWeight = 60.0;
  String activityLevel = AppConfig.activityLevelModerate;
  String goal = HealthGoal.lose.value;
  bool loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() async {
    if (step == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อของคุณ')),
      );
      return;
    }

    if (step < 4) {
      setState(() => step++);
      return;
    }

    setState(() => loading = true);
    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) throw Exception('No user found');

      final now = DateTimeUtils.now();
      int currentAge = now.year - birthYear;
      if (now.month < birthMonth) currentAge--;
      if (currentAge <= 0) currentAge = 1;

      final stats = HealthProfileStats.calculate(
        weight: weight,
        height: height,
        age: currentAge,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
      );

      final profile = UserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        gender: gender,
        birthMonth: birthMonth,
        birthYear: birthYear,
        height: height,
        weight: weight,
        targetWeight: targetWeight,
        activityLevel: activityLevel,
        goal: goal,
        joinedDate: now,
        role: UserRole.user.value,
        streak: 1,
        tdee: stats.tdee,
        targetCalories: stats.targetCalories,
        targetProtein: stats.targetProtein,
        targetCarbs: stats.targetCarbs,
        targetFat: stats.targetFat,
        targetWaterGlasses: stats.targetWaterGlasses,
      );

      final fs = Provider.of<FirestoreService>(context, listen: false);
      await fs.saveUserProfile(user.uid, profile);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppLogger.error('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return AnimatedPageWrapper(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppTheme.maxContentWidth(screenWidth),
            ),
            child: Padding(
              padding: AppTheme.pageInsetsForWidth(
                screenWidth,
                top: 24,
                bottom: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildStepIndicator(),
                  const SizedBox(height: 32),
                  Text(
                    'ยินดีต้อนรับ!',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เรามาตั้งค่าเป้าหมายสุขภาพของคุณกันเถอะ',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      clipBehavior: Clip.none,
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        opacity: 0.15,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const LeafDecoration(
                              alignment: Alignment.topLeft,
                              color: AppTheme.leafGreen,
                              size: 62,
                              opacity: 0.11,
                              angle: -0.35,
                            ),
                            const LeafDecoration(
                              alignment: Alignment.bottomRight,
                              color: AppTheme.warmOrange,
                              size: 52,
                              opacity: 0.14,
                              angle: 0.55,
                            ),
                            Column(
                              children: [
                                if (step == 1) ...[
                                  _buildLabel('ชื่อเล่น'),
                                  TextField(
                                    controller: _nameController,
                                    decoration: const InputDecoration(
                                      hintText: 'ชื่อของคุณ',
                                      prefixIcon:
                                          Icon(LucideIcons.user, size: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _buildLabel('เพศ'),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _buildSelectButton(
                                              'male',
                                              'ชาย',
                                              gender == Gender.male.value,
                                              () => setState(() =>
                                                  gender = Gender.male.value))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: _buildSelectButton(
                                              'female',
                                              'หญิง',
                                              gender == Gender.female.value,
                                              () => setState(() => gender =
                                                  Gender.female.value))),
                                    ],
                                  ),
                                ] else if (step == 2) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _buildNumberInput(
                                              'เดือนเกิด (1-12)',
                                              birthMonth.toString(),
                                              LucideIcons.calendar,
                                              (v) => setState(() => birthMonth =
                                                  int.tryParse(v) ??
                                                      birthMonth))),
                                      const SizedBox(width: 16),
                                      Expanded(
                                          child: _buildNumberInput(
                                              'ปีเกิด (ค.ศ.)',
                                              birthYear.toString(),
                                              LucideIcons.calendarDays,
                                              (v) => setState(() => birthYear =
                                                  int.tryParse(v) ??
                                                      birthYear))),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _buildNumberInput(
                                              'ส่วนสูง (ซม.)',
                                              height.toString(),
                                              LucideIcons.ruler,
                                              (v) => setState(() => height =
                                                  double.tryParse(v) ??
                                                      height))),
                                      const SizedBox(width: 16),
                                      Expanded(
                                          child: _buildNumberInput(
                                              'น้ำหนัก (กก.)',
                                              weight.toString(),
                                              LucideIcons.scale, (v) {
                                        setState(() {
                                          weight = double.tryParse(v) ?? weight;
                                        });
                                      })),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildNumberInput(
                                      'น้ำหนักเป้าหมาย (กก.)',
                                      targetWeight.toString(),
                                      LucideIcons.target,
                                      (v) => setState(() => targetWeight =
                                          double.tryParse(v) ?? targetWeight)),
                                ] else if (step == 3) ...[
                                  _buildLabel('ระดับกิจกรรมของคุณ'),
                                  _buildActivityOption(
                                      AppConfig.activityLevelSedentary,
                                      'นั่งทำงานเป็นหลัก',
                                      'ออกกำลังกายน้อยมาก'),
                                  _buildActivityOption(
                                      AppConfig.activityLevelLightly,
                                      'เคลื่อนไหวบ้าง',
                                      'ออกกำลังกาย 1-3 วัน/สัปดาห์'),
                                  _buildActivityOption(
                                      AppConfig.activityLevelModerate,
                                      'ปานกลาง',
                                      'ออกกำลังกาย 3-5 วัน/สัปดาห์'),
                                  _buildActivityOption(
                                      AppConfig.activityLevelVery,
                                      'หนัก',
                                      'ออกกำลังกาย 6-7 วัน/สัปดาห์'),
                                ] else if (step == 4) ...[
                                  _buildLabel('เป้าหมายของคุณ'),
                                  _buildGoalOption(HealthGoal.lose.value,
                                      'ลดน้ำหนัก', 'ลดไขมัน เน้นแคลอรี่ต่ำ'),
                                  _buildGoalOption(
                                      HealthGoal.maintain.value,
                                      'รักษาน้ำหนัก',
                                      'กินเท่าที่ใช้ ไม่เพิ่มไม่ลด'),
                                  _buildGoalOption(
                                      HealthGoal.gain.value,
                                      'เพิ่มกล้ามเนื้อ',
                                      'เพิ่มน้ำหนักและกล้ามเนื้อ'),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: loading ? null : _nextStep,
                    isLoading: loading,
                    text: step == 4 ? 'เริ่มต้นใช้งาน' : 'ถัดไป',
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = step > index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 32 : 12,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : AppTheme.pageTintStrong,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    fontSize: 16))),
      );

  Widget _buildSelectButton(
      String value, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: AppTheme.innerRadius,
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.cardBorder.withValues(alpha: 0.8),
          ),
          boxShadow:
              selected ? AppTheme.softShadow(AppTheme.primaryColor) : null,
        ),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppTheme.mutedText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16))),
      ),
    );
  }

  Widget _buildNumberInput(
      String label, String value, IconData icon, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: value,
            prefixIcon: Icon(icon, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityOption(String id, String label, String sub) {
    final selected = activityLevel == id;
    return GestureDetector(
      onTap: () => setState(() => activityLevel = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.cardBorder.withValues(alpha: 0.8),
          ),
          boxShadow:
              selected ? AppTheme.softShadow(AppTheme.primaryColor) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: selected ? Colors.white : AppTheme.ink)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.mutedText)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalOption(String id, String label, String sub) {
    final selected = goal == id;
    return GestureDetector(
      onTap: () => setState(() => goal = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.cardBorder.withValues(alpha: 0.8),
          ),
          boxShadow:
              selected ? AppTheme.softShadow(AppTheme.primaryColor) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: selected ? Colors.white : AppTheme.ink)),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.mutedText)),
          ],
        ),
      ),
    );
  }
}
