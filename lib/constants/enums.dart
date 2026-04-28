// Enumeration types used throughout the Foodcal app.
// Using enums instead of magic strings improves type safety and reduces bugs.

/// User roles in the system.
enum UserRole {
  user('user'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? str) {
    return UserRole.values.firstWhere(
      (e) => e.value == str,
      orElse: () => UserRole.user,
    );
  }
}

/// Health goals for the user.
enum HealthGoal {
  lose('lose'),
  maintain('maintain'),
  gain('gain');

  final String value;
  const HealthGoal(this.value);

  static HealthGoal fromString(String? str) {
    return HealthGoal.values.firstWhere(
      (e) => e.value == str,
      orElse: () => HealthGoal.maintain,
    );
  }

  String get displayName {
    switch (this) {
      case HealthGoal.lose:
        return 'ลดน้ำหนัก';
      case HealthGoal.maintain:
        return 'รักษาน้ำหนัก';
      case HealthGoal.gain:
        return 'เพิ่มน้ำหนัก';
    }
  }
}

/// Activity levels for calculating TDEE.
enum ActivityLevel {
  sedentary('sedentary', 1.2),
  lightly('lightly', 1.375),
  moderate('moderate', 1.55),
  very('very', 1.725),
  extremely('extremely', 1.9);

  final String value;
  final double multiplier;
  const ActivityLevel(this.value, this.multiplier);

  static ActivityLevel fromString(String? str) {
    return ActivityLevel.values.firstWhere(
      (e) => e.value == str,
      orElse: () => ActivityLevel.moderate,
    );
  }

  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'นั่งส่วนใหญ่ (Sedentary)';
      case ActivityLevel.lightly:
        return 'ออกกำลังกายเบา (Lightly Active)';
      case ActivityLevel.moderate:
        return 'ออกกำลังกายปกติ (Moderate)';
      case ActivityLevel.very:
        return 'ออกกำลังกายหนัก (Very Active)';
      case ActivityLevel.extremely:
        return 'ออกกำลังกายเข้มข้นมาก (Extremely Active)';
    }
  }
}

/// Biological gender (for TDEE calculation).
enum Gender {
  male('male'),
  female('female');

  final String value;
  const Gender(this.value);

  static Gender fromString(String? str) {
    return Gender.values.firstWhere(
      (e) => e.value == str,
      orElse: () => Gender.male,
    );
  }
}

/// Workout types for categorization.
enum WorkoutType {
  cardio('Cardio'),
  strength('Strength'),
  hiit('HIIT'),
  yoga('Yoga'),
  pilates('Pilates'),
  stretch('Stretch');

  final String value;
  const WorkoutType(this.value);

  static WorkoutType fromString(String? str) {
    return WorkoutType.values.firstWhere(
      (e) => e.value == str,
      orElse: () => WorkoutType.cardio,
    );
  }
}

/// Difficulty levels for workouts and exercises.
enum DifficultyLevel {
  beginner('Beginner'),
  intermediate('Intermediate'),
  expert('Expert');

  final String value;
  const DifficultyLevel(this.value);

  static DifficultyLevel fromString(String? str) {
    return DifficultyLevel.values.firstWhere(
      (e) => e.value == str,
      orElse: () => DifficultyLevel.beginner,
    );
  }
}
