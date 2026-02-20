
class FoodItem {
  String name;
  int calories;
  int protein;
  int carbs;
  int fat;
  DateTime time;
  String mealType; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'

  FoodItem({
    required this.name, 
    required this.calories, 
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.time,
    this.mealType = 'Snack'
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] ?? '',
      calories: (map['calories'] ?? 0).toInt(),
      protein: (map['protein'] ?? 0).toInt(),
      carbs: (map['carbs'] ?? 0).toInt(),
      fat: (map['fat'] ?? 0).toInt(),
      time: DateTime.parse(map['time'] ?? DateTime.now().toIso8601String()),
      mealType: map['mealType'] ?? 'Snack',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'time': time.toIso8601String(),
      'mealType': mealType,
    };
  }
}

class WorkoutItem {
  int id;
  String title;
  String level;
  String duration;
  String type;
  DateTime completedAt;

  WorkoutItem({
    required this.id,
    required this.title,
    required this.level,
    required this.duration,
    required this.type,
    required this.completedAt,
  });

  factory WorkoutItem.fromMap(Map<String, dynamic> map) {
    return WorkoutItem(
      id: (map['id'] ?? 0).toInt(),
      title: map['title'] ?? '',
      level: map['level'] ?? '',
      duration: map['duration'] ?? '',
      type: map['type'] ?? '',
      completedAt: DateTime.parse(map['completedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'level': level,
      'duration': duration,
      'type': type,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

class DailyLog {
  String date; // YYYY-MM-DD
  int caloriesIn;
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
      protein: (map['protein'] ?? 0).toInt(),
      carbs: (map['carbs'] ?? 0).toInt(),
      fat: (map['fat'] ?? 0).toInt(),
      waterGlasses: (map['waterGlasses'] ?? 0).toInt(),
      foods: (map['foods'] as List<dynamic>? ?? []).map((e) => FoodItem.fromMap(e)).toList(),
      workouts: (map['workouts'] as List<dynamic>? ?? []).map((e) => WorkoutItem.fromMap(e)).toList(),
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'caloriesIn': caloriesIn,
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
