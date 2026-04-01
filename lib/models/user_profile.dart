
import '../utils/health_profile_stats.dart';

class UserProfile {
  String uid;
  String name;
  String gender;
  int age;
  double height;
  double weight;
  String activityLevel;
  String goal; // 'lose', 'maintain', 'gain'
  
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
    required this.age,
    required this.height,
    required this.weight,
    required this.activityLevel,
    required this.goal,
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
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    final age = (map['age'] ?? 25).toInt();
    final height = (map['height'] ?? 170).toDouble();
    final weight = (map['weight'] ?? 60).toDouble();
    final gender = map['gender'] ?? 'male';
    final activityLevel = map['activityLevel'] ?? 'moderate';
    final goal = map['goal'] ?? 'maintain';
    final stats = HealthProfileStats.calculate(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
    );

    return UserProfile(
      uid: uid,
      name: map['name'] ?? '',
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      goal: goal,
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
      'age': age,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'goal': goal,

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
      'age': age,
      'height': height,
      'weight': weight,
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
    int? age,
    double? height,
    double? weight,
    String? activityLevel,
    String? goal,
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
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
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
