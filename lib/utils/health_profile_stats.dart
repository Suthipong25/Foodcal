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
    bmr += (gender == 'male' ? 5 : -161);

    final activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
    };

    final tdee = (bmr * (activityMultipliers[activityLevel] ?? 1.2)).round();

    int targetCalories = tdee;
    if (goal == 'lose') {
      targetCalories = tdee - 500;
    } else if (goal == 'gain') {
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
