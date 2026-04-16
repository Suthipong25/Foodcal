
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/daily_log.dart';
import '../models/feedback_log.dart';
import '../utils/health_profile_stats.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int _maxSingleFoodCalories = 5000;
  static const int _maxSingleMacroGrams = 500;
  static const int _maxDailyCaloriesIn = 20000;
  static const int _maxDailyCaloriesOut = 10000;
  static const int _maxWaterGlasses = 40;

  // --- Collection References ---
  CollectionReference get _usersRef => _db.collection('users');

  void _validateFoodItem(FoodItem food) {
    if (food.name.trim().isEmpty) {
      throw ArgumentError('Food name is required.');
    }

    final values = [food.calories, food.protein, food.carbs, food.fat];
    if (values.any((value) => value < 0)) {
      throw ArgumentError('Food values must be non-negative.');
    }

    if (food.calories > _maxSingleFoodCalories ||
        food.protein > _maxSingleMacroGrams ||
        food.carbs > _maxSingleMacroGrams ||
        food.fat > _maxSingleMacroGrams) {
      throw ArgumentError('Food values exceed safe limits.');
    }
  }

  void _validateWorkout(WorkoutItem workout) {
    if (workout.id <= 0) {
      throw ArgumentError('Workout id is invalid.');
    }
    if (workout.title.trim().isEmpty) {
      throw ArgumentError('Workout title is required.');
    }
    if (workout.minutes < 1 || workout.minutes > 180) {
      throw ArgumentError('Workout duration is out of range.');
    }
  }

  // --- Profile Operations ---

  // Stream User Profile
  // New Structure: /users/{uid}
  Stream<UserProfile?> streamUserProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromMap(uid, snapshot.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Create/Update Profile
  Future<void> saveUserProfile(String uid, UserProfile profile) async {
    await _usersRef.doc(uid).set(profile.toEditableMap(), SetOptions(merge: true));
  }

  // Update Login Streak
  Future<void> updateLoginStreak(String uid, UserProfile profile) async {
    // Streak updates must be handled by a trusted backend to avoid spoofing client time.
    return;
  }
  
  // TDEE Calculation Helper (Static)
  static Map<String, int> calculateStats(double weight, double height, int age, String gender, String activityLevel, String goal) {
    final stats = HealthProfileStats.calculate(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
    );
    return {
      'tdee': stats.tdee,
      'targetCalories': stats.targetCalories,
      'targetProtein': stats.targetProtein,
      'targetCarbs': stats.targetCarbs,
      'targetFat': stats.targetFat,
      'targetWaterGlasses': stats.targetWaterGlasses,
    };
  }

  // --- Daily Log Operations ---
  // New Structure: /users/{uid}/daily_logs/{YYYY-MM-DD}

  static String utcDateKey([DateTime? dateTime]) {
    final now = (dateTime ?? DateTime.now()).toUtc();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DocumentReference _getTodayLogRef(String uid) {
    return _usersRef.doc(uid).collection('daily_logs').doc(utcDateKey());
  }

  Stream<DailyLog?> streamDailyLog(String uid) {
    return _getTodayLogRef(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return DailyLog.fromMap(snapshot.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    });
  }

  Future<void> addFood(String uid, FoodItem food) async {
    _validateFoodItem(food);
    DocumentReference logRef = _getTodayLogRef(uid);
    
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(logRef);
      if (!snapshot.exists) {
        final newLog = DailyLog(
          date: logRef.id,
          caloriesIn: food.calories,
          protein: food.protein,
          carbs: food.carbs,
          fat: food.fat,
          waterGlasses: 0,
          foods: [food],
          workouts: [],
          lastUpdated: DateTime.now(),
        );
        final logData = newLog.toMap();
        logData['lastUpdated'] = FieldValue.serverTimestamp();
        transaction.set(logRef, logData);
      } else {
        Map data = snapshot.data() as Map;
        int currentCals = data['caloriesIn'] ?? 0;
        int currentProtein = data['protein'] ?? 0;
        int currentCarbs = data['carbs'] ?? 0;
        int currentFat = data['fat'] ?? 0;
        final newCalories = currentCals + food.calories;
        if (newCalories > _maxDailyCaloriesIn) {
          throw StateError('Daily calories exceed the allowed limit.');
        }

        transaction.update(logRef, {
          'caloriesIn': newCalories,
          'protein': currentProtein + food.protein,
          'carbs': currentCarbs + food.carbs,
          'fat': currentFat + food.fat,
          'foods': FieldValue.arrayUnion([food.toMap()]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> updateWater(String uid, int delta) async {
    if (![1, 2, 6, -1].contains(delta)) {
      throw ArgumentError('Unsupported water delta.');
    }

    DocumentReference logRef = _getTodayLogRef(uid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(logRef);
      if (!snapshot.exists) {
        if (delta > 0) {
           final newLog = DailyLog(
            date: logRef.id,
            caloriesIn: 0,
            waterGlasses: delta,
            foods: [],
            workouts: [],
            lastUpdated: DateTime.now(),
          );
          final logData = newLog.toMap();
          logData['lastUpdated'] = FieldValue.serverTimestamp();
          transaction.set(logRef, logData);
        }
      } else {
        int currentWater = (snapshot.data() as Map)['waterGlasses'] ?? 0;
        int newValue = currentWater + delta;
        if(newValue < 0) newValue = 0;
        if (newValue > _maxWaterGlasses) {
          throw StateError('Daily water exceeds the allowed limit.');
        }
        
        transaction.update(logRef, {
          'waterGlasses': newValue,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> finishWorkout(String uid, WorkoutItem workout) async {
    _validateWorkout(workout);
    DocumentReference logRef = _getTodayLogRef(uid);
    
    // Estimate calories burned based on duration and level
    int minutes = workout.minutes;
    int calPerMin = 5; // Beginner
    if (workout.level == 'Intermediate') calPerMin = 7;
    if (workout.level == 'Expert') calPerMin = 10;
    int burned = minutes * calPerMin;

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(logRef);
      if (!snapshot.exists) {
        final newLog = DailyLog(
            date: logRef.id,
            caloriesIn: 0,
            caloriesOut: burned,
            waterGlasses: 0,
            foods: [],
            workouts: [workout],
            lastUpdated: DateTime.now(),
          );
        final logData = newLog.toMap();
        logData['lastUpdated'] = FieldValue.serverTimestamp();
        transaction.set(logRef, logData);
      } else {
        Map data = snapshot.data() as Map;
        int currentOut = data['caloriesOut'] ?? 0;
        final existingWorkouts = (data['workouts'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((item) => WorkoutItem.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        if (existingWorkouts.any((item) => item.id == workout.id)) {
          return;
        }

        final newCaloriesOut = currentOut + burned;
        if (newCaloriesOut > _maxDailyCaloriesOut) {
          throw StateError('Daily workout calories exceed the allowed limit.');
        }

        transaction.update(logRef, {
          'caloriesOut': newCaloriesOut,
          'workouts': FieldValue.arrayUnion([workout.toMap()]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Stream All Daily Logs (History)
  Stream<List<DailyLog>> streamDailyLogs(String uid, {int limit = 30}) {
    return _usersRef
        .doc(uid)
        .collection('daily_logs')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DailyLog.fromMap(doc.data()))
          .toList();
    });
  }

  // Get Recent Unique Foods (Last 7 days)
  Future<List<FoodItem>> getRecentUniqueFoods(String uid) async {
    final snapshot = await _usersRef
        .doc(uid)
        .collection('daily_logs')
        .orderBy('date', descending: true)
        .limit(7)
        .get();

    final List<FoodItem> recentFoods = [];
    final Set<String> uniqueNames = {};

    for (var doc in snapshot.docs) {
      final log = DailyLog.fromMap(doc.data());
      for (var food in log.foods) {
        if (!uniqueNames.contains(food.name.toLowerCase())) {
          recentFoods.add(food);
          uniqueNames.add(food.name.toLowerCase());
        }
      }
    }
    
    // Sort by name or keep original order (latest first)
    return recentFoods.take(10).toList();
  }

  // --- Feedback Operations ---
  Future<void> submitFeedback(FeedbackLog log) async {
    await _db.collection('feedback').add(log.toMap());
  }

  Stream<List<FeedbackLog>> streamAllFeedback() {
    return _db
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FeedbackLog.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}

