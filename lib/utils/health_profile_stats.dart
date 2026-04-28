import '../constants/app_config.dart';
import '../constants/enums.dart';

class HealthProfileStats {
  final int tdee;
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFat;
  final int targetWaterGlasses;

  const HealthProfileStats({
    required this.tdee,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    required this.targetWaterGlasses,
  });

  static HealthProfileStats calculate({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    bmr += (gender == Gender.male.value ? 5 : -161);

    final activityMultipliers = {
      AppConfig.activityLevelSedentary: 1.2,
      // legacy key support
      'light': 1.375,
      AppConfig.activityLevelLightly: 1.375,
      AppConfig.activityLevelModerate: 1.55,
      // legacy key support
      'active': 1.725,
      AppConfig.activityLevelVery: 1.725,
      AppConfig.activityLevelExtremely: 1.9,
    };

    final tdee = (bmr * (activityMultipliers[activityLevel] ?? 1.2)).round();

    int targetCalories = tdee;
    if (goal == HealthGoal.lose.value) {
      targetCalories = tdee - 500;
    } else if (goal == HealthGoal.gain.value) {
      targetCalories = tdee + 300;
    }

    if (targetCalories < 1200) targetCalories = 1200;

    final targetProtein = (weight * 1.5).round();
    final targetFat = ((targetCalories * 0.25) / 9).round();
    final remainingCals = targetCalories - (targetProtein * 4) - (targetFat * 9);
    final targetCarbs = ((remainingCals / 4).round()).clamp(0, 99999);

    var targetWaterGlasses = ((weight * 30) / 250).round();
    if (targetWaterGlasses < 6) targetWaterGlasses = 6;

    return HealthProfileStats(
      tdee: tdee,
      targetCalories: targetCalories,
      targetProtein: targetProtein,
      targetCarbs: targetCarbs,
      targetFat: targetFat,
      targetWaterGlasses: targetWaterGlasses,
    );
  }
}

class HealthProfileValidator {
  static const int minBirthMonth = 1;
  static const int maxBirthMonth = 12;
  static const int minBirthYear = 1900;
  static const int minHeightCm = 100;
  static const int maxHeightCm = 260;
  static const int minWeightKg = 20;
  static const int maxWeightKg = 400;

  static String? validate({
    required String name,
    required int birthMonth,
    required int birthYear,
    required double height,
    required double weight,
    required double? targetWeight,
    required String goal,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return 'กรุณากรอกชื่อ';
    }
    if (trimmedName.length > 80) {
      return 'ชื่อต้องมีความยาวไม่เกิน 80 ตัวอักษร';
    }

    if (birthMonth < minBirthMonth || birthMonth > maxBirthMonth) {
      return 'เดือนเกิดต้องอยู่ระหว่าง 1-12';
    }

    final currentYear = DateTime.now().year;
    if (birthYear < minBirthYear || birthYear > currentYear) {
      return 'ปีเกิดต้องอยู่ระหว่าง $minBirthYear-$currentYear';
    }

    if (height < minHeightCm || height > maxHeightCm) {
      return 'ส่วนสูงต้องอยู่ระหว่าง $minHeightCm-$maxHeightCm ซม.';
    }

    if (weight < minWeightKg || weight > maxWeightKg) {
      return 'น้ำหนักต้องอยู่ระหว่าง $minWeightKg-$maxWeightKg กก.';
    }

    if (targetWeight != null &&
        (targetWeight < minWeightKg || targetWeight > maxWeightKg)) {
      return 'น้ำหนักเป้าหมายต้องอยู่ระหว่าง $minWeightKg-$maxWeightKg กก.';
    }

    if (targetWeight != null) {
      if (goal == HealthGoal.lose.value && targetWeight > weight) {
        return 'เป้าหมายลดน้ำหนักต้องน้อยกว่าน้ำหนักปัจจุบัน';
      }
      if (goal == HealthGoal.gain.value && targetWeight < weight) {
        return 'เป้าหมายเพิ่มน้ำหนักต้องมากกว่าน้ำหนักปัจจุบัน';
      }
    }

    return null;
  }
}
