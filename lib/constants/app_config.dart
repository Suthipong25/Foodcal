/// Centralized configuration and constants for the Foodcal app.
/// This eliminates magic numbers scattered throughout the codebase.
class AppConfig {
  // ── Timezone ──────────────────────────────────────────────────────────────
  static const int bangkokUtcOffsetHours = 7;

  // ── Food Validation ───────────────────────────────────────────────────────
  static const int maxFoodNameLength = 150;
  static const int maxSingleFoodCalories = 5000;
  static const int maxSingleMacroGrams = 500;
  static const int maxDailyCalories = 20000;
  static const int maxDailyWorkoutCalories = 10000;
  static const int maxDailyWaterGlasses = 40;

  // ── Workout Validation ────────────────────────────────────────────────────
  static const int minWorkoutMinutes = 1;
  static const int maxWorkoutMinutes = 180;

  // ── API Timeouts ──────────────────────────────────────────────────────────
  static const Duration geminiRequestTimeout = Duration(seconds: 30);
  static const Duration firebaseWriteTimeout = Duration(seconds: 15);

  // ── Retry Configuration ───────────────────────────────────────────────────
  static const int maxRetryAttempts = 3;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  // ── User Profile ──────────────────────────────────────────────────────────
  static const int defaultTargetWaterGlasses = 8;
  static const int defaultAge = 25;
  static const double defaultHeight = 170.0;
  static const double defaultWeight = 60.0;

  // ── Meal Type ─────────────────────────────────────────────────────────────
  static const String mealTypeBreakfast = 'Breakfast';
  static const String mealTypeLunch = 'Lunch';
  static const String mealTypeDinner = 'Dinner';
  static const String mealTypeSnack = 'Snack';

  static const List<String> mealTypes = [
    mealTypeBreakfast,
    mealTypeLunch,
    mealTypeDinner,
    mealTypeSnack,
  ];

  // ── Activity Level ────────────────────────────────────────────────────────
  static const String activityLevelSedentary = 'sedentary';
  static const String activityLevelLightly = 'lightly';
  static const String activityLevelModerate = 'moderate';
  static const String activityLevelVery = 'very';
  static const String activityLevelExtremely = 'extremely';

  static const List<String> activityLevels = [
    activityLevelSedentary,
    activityLevelLightly,
    activityLevelModerate,
    activityLevelVery,
    activityLevelExtremely,
  ];

  // ── UI Constants ──────────────────────────────────────────────────────────
  static const int maxContentWidth = 800;
  static const double pageHorizontalPadding = 16.0;
  static const double pageVerticalPadding = 24.0;
}
