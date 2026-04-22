
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
  String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'

  FoodItem({
    String? id,
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.time,
    this.mealType = 'Snack',
  }) : id = id ?? '';

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as String? ?? '',
      name: map['name'] ?? '',
      calories: (map['calories'] ?? 0).toInt(),
      protein: (map['protein'] ?? 0).toInt(),
      carbs: (map['carbs'] ?? 0).toInt(),
      fat: (map['fat'] ?? 0).toInt(),
      time: _parseDate(map['time']) ?? DateTime.now(),
      mealType: map['mealType'] ?? 'Snack',
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
      id: (map['id'] ?? 0).toInt(),
      title: map['title'] ?? '',
      level: map['level'] ?? '',
      duration: map['duration'] ?? '',
      minutes: (map['minutes'] ??
              int.tryParse((map['duration'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
              0)
          .toInt(),
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
      caloriesIn: (map['caloriesIn'] ?? 0).toInt(),
      caloriesOut: (map['caloriesOut'] ?? 0).toInt(),
      protein: (map['protein'] ?? 0).toInt(),
      carbs: (map['carbs'] ?? 0).toInt(),
      fat: (map['fat'] ?? 0).toInt(),
      waterGlasses: (map['waterGlasses'] ?? 0).toInt(),
      foods: (map['foods'] as List<dynamic>? ?? []).map((e) => FoodItem.fromMap(e)).toList(),
      workouts: (map['workouts'] as List<dynamic>? ?? []).map((e) => WorkoutItem.fromMap(e)).toList(),
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
      workoutId: (map['workoutId'] ?? 0).toInt(),
      dateKey: map['dateKey'] ?? '',
      minutes: (map['minutes'] ?? 0).toInt(),
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
