import '../constants/app_config.dart';

class FoodItem {
  /// Unique identifier generated at creation time (UUID v4).
  /// Older entries loaded from Firestore may have an empty string.
  String id;
  String name;
  int calories;
  int protein;
  int carbs;
  int fat;
  DateTime time;
  String mealType;

  FoodItem({
    String? id,
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.time,
    this.mealType = AppConfig.mealTypeSnack,
  }) : id = id ?? '';

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    final name = _safeString(map['name']) ?? '';
    final calories = _safeInt(map['calories']) ?? 0;
    final protein = _safeInt(map['protein']) ?? 0;
    final carbs = _safeInt(map['carbs']) ?? 0;
    final fat = _safeInt(map['fat']) ?? 0;
    final mealType = _safeString(map['mealType']) ?? AppConfig.mealTypeSnack;

    return FoodItem(
      id: map['id'] as String? ?? '',
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      time: _parseDate(map['time']) ?? DateTime.now(),
      mealType: mealType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'time': time.toIso8601String(),
      'mealType': mealType,
    };
  }

  FoodItem copyWith({
    String? id,
    String? name,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    DateTime? time,
    String? mealType,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      time: time ?? this.time,
      mealType: mealType ?? this.mealType,
    );
  }
}

class WorkoutItem {
  int id;
  String title;
  String level;
  String duration;
  int minutes;
  String type;
  DateTime completedAt;

  WorkoutItem({
    required this.id,
    required this.title,
    required this.level,
    required this.duration,
    required this.minutes,
    required this.type,
    required this.completedAt,
  });

  factory WorkoutItem.fromMap(Map<String, dynamic> map) {
    return WorkoutItem(
      id: _safeInt(map['id']) ?? 0,
      title: map['title'] ?? '',
      level: map['level'] ?? '',
      duration: map['duration'] ?? '',
      minutes: _safeInt(map['minutes']) ??
          int.tryParse(
                (map['duration'] ?? '')
                    .toString()
                    .replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
          0,
      type: map['type'] ?? '',
      completedAt: _parseDate(map['completedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'level': level,
      'duration': duration,
      'minutes': minutes,
      'type': type,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

class DailyLog {
  String date; // YYYY-MM-DD
  int caloriesIn;
  int caloriesOut;
  int protein;
  int carbs;
  int fat;
  int waterGlasses;
  List<FoodItem> foods;
  List<WorkoutItem> workouts;
  DateTime lastUpdated;

  DailyLog({
    required this.date,
    required this.caloriesIn,
    this.caloriesOut = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.waterGlasses,
    required this.foods,
    required this.workouts,
    required this.lastUpdated,
  });

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      date: map['date'] ?? '',
      caloriesIn: _safeInt(map['caloriesIn']) ?? 0,
      caloriesOut: _safeInt(map['caloriesOut']) ?? 0,
      protein: _safeInt(map['protein']) ?? 0,
      carbs: _safeInt(map['carbs']) ?? 0,
      fat: _safeInt(map['fat']) ?? 0,
      waterGlasses: _safeInt(map['waterGlasses']) ?? 0,
      foods: (map['foods'] as List<dynamic>? ?? [])
          .map((e) => FoodItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      workouts: (map['workouts'] as List<dynamic>? ?? [])
          .map((e) => WorkoutItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      lastUpdated: _parseDate(map['lastUpdated']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'caloriesIn': caloriesIn,
      'caloriesOut': caloriesOut,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'waterGlasses': waterGlasses,
      'foods': foods.map((e) => e.toMap()).toList(),
      'workouts': workouts.map((e) => e.toMap()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class WorkoutSessionState {
  final int workoutId;
  final String dateKey;
  final int minutes;
  final DateTime startedAt;
  final bool completed;
  final DateTime? completedAt;

  const WorkoutSessionState({
    required this.workoutId,
    required this.dateKey,
    required this.minutes,
    required this.startedAt,
    required this.completed,
    this.completedAt,
  });

  factory WorkoutSessionState.fromMap(Map<String, dynamic> map) {
    return WorkoutSessionState(
      workoutId: _safeInt(map['workoutId']) ?? 0,
      dateKey: map['dateKey'] ?? '',
      minutes: _safeInt(map['minutes']) ?? 0,
      startedAt: _parseDate(map['startedAt']) ?? DateTime.now(),
      completed: map['completed'] == true,
      completedAt: _parseDate(map['completedAt']),
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

/// Safely parse an integer from a map value
int? _safeInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}

/// Safely parse a string from a map value
String? _safeString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}
