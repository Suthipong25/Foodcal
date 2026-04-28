import '../utils/health_profile_stats.dart';
import '../constants/app_config.dart';
import '../constants/enums.dart';

class UserProfile {
  String uid;
  String name;
  String gender;
  int? birthMonth;
  int? birthYear;
  int? _legacyAge;
  double height;
  double weight;
  double? targetWeight;
  String activityLevel;
  String goal;
  String role;

  int get age {
    if (birthYear != null && birthMonth != null) {
      final now = DateTime.now();
      int calculatedAge = now.year - birthYear!;
      if (now.month < birthMonth!) calculatedAge--;
      return calculatedAge > 0 ? calculatedAge : 1;
    }
    return _legacyAge ?? 25;
  }

  int get estimatedGoalDays {
    if (targetWeight == null ||
        targetWeight == weight ||
        goal == HealthGoal.maintain.value) {
      return 0;
    }

    int dailyDiff;
    if (goal == HealthGoal.lose.value) {
      if (targetWeight! > weight) {
        return 0; // cannot lose weight to reach a higher target
      }
      dailyDiff = tdee - targetCalories;
      if (dailyDiff <= 0) dailyDiff = 500;
    } else if (goal == HealthGoal.gain.value) {
      if (targetWeight! < weight) {
        return 0; // cannot gain weight to reach a lower target
      }
      dailyDiff = targetCalories - tdee;
      if (dailyDiff <= 0) dailyDiff = 300;
    } else {
      return 0;
    }

    final totalKgDiff = (weight - targetWeight!).abs();
    final totalKcalDiff = totalKgDiff * 7700;
    return (totalKcalDiff / dailyDiff).ceil();
  }

  DateTime? get estimatedGoalDate {
    final days = estimatedGoalDays;
    if (days <= 0) return null;
    return DateTime.now().add(Duration(days: days));
  }

  // Stats
  int tdee;
  int targetCalories;
  int targetProtein;
  int targetCarbs;
  int targetFat;

  int targetWaterGlasses;
  int streak;
  DateTime joinedDate;
  DateTime? lastLoginDate;
  String? photoUrl;

  UserProfile({
    required this.uid,
    required this.name,
    required this.gender,
    this.birthMonth,
    this.birthYear,
    int? legacyAge,
    required this.height,
    required this.weight,
    this.targetWeight,
    required this.activityLevel,
    required this.goal,
    this.role = 'user',
    required this.tdee,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    this.targetWaterGlasses = 8,
    this.streak = 0,
    required this.joinedDate,
    this.lastLoginDate,
    this.photoUrl,
  }) : _legacyAge = legacyAge;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    // Parse age fields with null safety
    final legacyAge = (map['age'] as num?)?.toInt();
    final birthMonth = (map['birthMonth'] as num?)?.toInt();
    final birthYear = (map['birthYear'] as num?)?.toInt();

    int currentAge = legacyAge ?? AppConfig.defaultAge;
    if (birthYear != null && birthMonth != null) {
      final now = DateTime.now();
      currentAge = now.year - birthYear;
      if (now.month < birthMonth) currentAge--;
      if (currentAge <= 0) currentAge = 1;
    }

    // Parse dimensions with defaults and null safety
    final height = _safeDouble(map['height']) ?? AppConfig.defaultHeight;
    final weight = _safeDouble(map['weight']) ?? AppConfig.defaultWeight;
    final targetWeight =
        map['targetWeight'] != null ? _safeDouble(map['targetWeight']) : null;

    // Parse profile settings with safe fallbacks
    final gender = _safeString(map['gender']) ?? Gender.male.value;
    final activityLevel =
        _safeString(map['activityLevel']) ?? ActivityLevel.moderate.value;
    final goal = _safeString(map['goal']) ?? HealthGoal.maintain.value;
    final role = _safeString(map['role']) ?? UserRole.user.value;
    final name = _safeString(map['name']) ?? '';

    final stats = HealthProfileStats.calculate(
      weight: weight,
      height: height,
      age: currentAge,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
    );

    return UserProfile(
      uid: uid,
      name: name,
      gender: gender,
      birthMonth: birthMonth,
      birthYear: birthYear,
      legacyAge: legacyAge,
      height: height,
      weight: weight,
      targetWeight: targetWeight,
      activityLevel: activityLevel,
      goal: goal,
      role: role,
      tdee: stats.tdee,
      targetCalories: stats.targetCalories,
      targetProtein: stats.targetProtein,
      targetCarbs: stats.targetCarbs,
      targetFat: stats.targetFat,
      targetWaterGlasses: stats.targetWaterGlasses,
      streak: (map['streak'] ?? 0).toInt(),
      joinedDate: _parseDate(map['joinedDate']) ?? DateTime.now(),
      lastLoginDate: _parseDate(map['lastLoginDate']),
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'birthMonth': birthMonth,
      'birthYear': birthYear,
      'age': age,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel,
      'goal': goal,
      'role': role,
      'tdee': tdee,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
      'targetWaterGlasses': targetWaterGlasses,
      'streak': streak,
      'joinedDate': joinedDate.toIso8601String(),
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  Map<String, dynamic> toEditableMap() {
    return {
      'name': name,
      'gender': gender,
      'birthMonth': birthMonth,
      'birthYear': birthYear,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'activityLevel': activityLevel,
      'goal': goal,
      'joinedDate': joinedDate.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? gender,
    int? birthMonth,
    int? birthYear,
    int? legacyAge,
    double? height,
    double? weight,
    double? targetWeight,
    String? activityLevel,
    String? goal,
    String? role,
    int? tdee,
    int? targetCalories,
    int? targetProtein,
    int? targetCarbs,
    int? targetFat,
    int? targetWaterGlasses,
    int? streak,
    DateTime? joinedDate,
    DateTime? lastLoginDate,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthMonth: birthMonth ?? this.birthMonth,
      birthYear: birthYear ?? this.birthYear,
      legacyAge: legacyAge ?? _legacyAge,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      role: role ?? this.role,
      tdee: tdee ?? this.tdee,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFat: targetFat ?? this.targetFat,
      targetWaterGlasses: targetWaterGlasses ?? this.targetWaterGlasses,
      streak: streak ?? this.streak,
      joinedDate: joinedDate ?? this.joinedDate,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
    );
  }

  // ── Static Helpers ────────────────────────────────────────────────────────

  /// Safely parse a double from a map value, handling various input types
  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    if (value is num) return value.toDouble();
    return null;
  }

  /// Safely parse a string from a map value
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  try {
    final dynamic dateTime = raw.toDate();
    if (dateTime is DateTime) return dateTime;
  } catch (_) {}
  return null;
}
