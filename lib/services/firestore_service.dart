
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_profile.dart';
import '../models/daily_log.dart';
import '../models/feedback_log.dart';
import '../utils/health_profile_stats.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int _maxSingleFoodCalories = 5000;
  static const int _maxSingleMacroGrams = 500;


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

  // Stream All Users (for Admin)
  Stream<List<UserProfile>> streamAllUsers() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }


  // --- Admin Operations ---
  Future<void> setAdminRole(String targetUid, bool promoteToAdmin) async {
    final callable = FirebaseFunctions.instance.httpsCallable('setAdminRole');
    await callable.call({'targetUid': targetUid, 'role': promoteToAdmin ? 'admin' : 'user'});
  }

  Future<void> deleteUserAccount(String targetUid) async {
    final callable = FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
    await callable.call({'targetUid': targetUid});
  }

  // Create/Update Profile
  Future<void> saveUserProfile(String uid, UserProfile profile) async {
    await _usersRef.doc(uid).set(profile.toEditableMap(), SetOptions(merge: true));
  }

  // Update Login Streak – writes directly to Firestore (works on Spark plan)
  Future<void> updateLoginStreak(String uid) async {
    final now = DateTime.now();
    // Compute Bangkok date key (UTC+7)
    final bkk = now.toUtc().add(const Duration(hours: 7));
    final todayKey =
        '${bkk.year.toString().padLeft(4, '0')}-${bkk.month.toString().padLeft(2, '0')}-${bkk.day.toString().padLeft(2, '0')}';

    final userRef = _usersRef.doc(uid);
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(userRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>? ?? {};
      final currentStreak = (data['streak'] as int?) ?? 0;
      final rawLastLogin = data['lastLoginDate'] as String?;

      // Parse lastLoginDate → compute its Bangkok date key
      String? lastKey;
      if (rawLastLogin != null) {
        final lastDt = DateTime.tryParse(rawLastLogin);
        if (lastDt != null) {
          final bkkLast = lastDt.toUtc().add(const Duration(hours: 7));
          lastKey =
              '${bkkLast.year.toString().padLeft(4, '0')}-${bkkLast.month.toString().padLeft(2, '0')}-${bkkLast.day.toString().padLeft(2, '0')}';
        }
      }

      if (lastKey == todayKey) return; // already synced today

      int nextStreak = 1;
      if (lastKey != null) {
        final last = DateTime.parse('${lastKey}T00:00:00Z');
        final today = DateTime.parse('${todayKey}T00:00:00Z');
        final diff = today.difference(last).inDays;
        if (diff == 1) nextStreak = currentStreak > 0 ? currentStreak + 1 : 1;
      }

      transaction.update(userRef, {
        'streak': nextStreak,
        'lastLoginDate': now.toUtc().toIso8601String(),
      });
    });
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

  static String dateKey([DateTime? dateTime]) {
    final now = (dateTime ?? DateTime.now()).toLocal();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String utcDateKey([DateTime? dateTime]) => dateKey(dateTime);

  DocumentReference _getTodayLogRef(String uid) {
    return _usersRef.doc(uid).collection('daily_logs').doc(dateKey());
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
    final logRef = _getTodayLogRef(uid);
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(logRef);
      final foodMap = food.toMap();
      if (!snap.exists) {
        transaction.set(logRef, {
          'date': dateKey(),
          'caloriesIn': food.calories,
          'caloriesOut': 0,
          'protein': food.protein,
          'carbs': food.carbs,
          'fat': food.fat,
          'waterGlasses': 0,
          'foods': [foodMap],
          'workouts': [],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return;
      }
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final foods = List<dynamic>.from(data['foods'] as List? ?? []);
      final caloriesIn = ((data['caloriesIn'] as num?)?.toInt() ?? 0) + food.calories;
      if (caloriesIn > 20000) throw Exception('Daily calories exceed the allowed limit.');
      foods.add(foodMap);
      transaction.update(logRef, {
        'caloriesIn': caloriesIn,
        'protein': ((data['protein'] as num?)?.toInt() ?? 0) + food.protein,
        'carbs': ((data['carbs'] as num?)?.toInt() ?? 0) + food.carbs,
        'fat': ((data['fat'] as num?)?.toInt() ?? 0) + food.fat,
        'foods': foods,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateWater(String uid, int delta) async {
    if (![1, 2, 6, -1].contains(delta)) {
      throw ArgumentError('Unsupported water delta.');
    }
    final logRef = _getTodayLogRef(uid);
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(logRef);
      if (!snap.exists) {
        if (delta <= 0) return;
        transaction.set(logRef, {
          'date': dateKey(),
          'caloriesIn': 0,
          'caloriesOut': 0,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
          'waterGlasses': delta,
          'foods': [],
          'workouts': [],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        return;
      }
      final data = snap.data() as Map<String, dynamic>? ?? {};
      int next = ((data['waterGlasses'] as num?)?.toInt() ?? 0) + delta;
      if (next < 0) next = 0;
      if (next > 40) throw Exception('Daily water exceeds the allowed limit.');
      transaction.update(logRef, {
        'waterGlasses': next,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> startWorkoutSession(String uid, WorkoutItem workout) async {
    _validateWorkout(workout);
    final sessionRef = _usersRef
        .doc(uid)
        .collection('workout_sessions')
        .doc(workout.id.toString());
    await sessionRef.set({
      'workoutId': workout.id,
      'minutes': workout.minutes,
      'dateKey': dateKey(),
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      'completed': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> finishWorkout(String uid, WorkoutItem workout) async {
    _validateWorkout(workout);
    final logRef = _getTodayLogRef(uid);
    final sessionRef = _usersRef
        .doc(uid)
        .collection('workout_sessions')
        .doc(workout.id.toString());

    await _db.runTransaction((transaction) async {
      final sessionSnap = await transaction.get(sessionRef);
      if (!sessionSnap.exists) throw Exception('Workout session not started.');

      final sessionData = (sessionSnap.data() ?? {}) as Map<String, dynamic>;
      final startedAt = DateTime.tryParse(sessionData['startedAt'] as String? ?? '');
      if (sessionData['dateKey'] != dateKey() || startedAt == null) {
        throw Exception('Workout session is no longer valid.');
      }

      final requiredMinutes = (workout.minutes * 0.6).ceil().clamp(1, workout.minutes);
      final elapsed = DateTime.now().difference(startedAt).inMinutes;
      if (elapsed < requiredMinutes) {
        throw Exception('Need at least $requiredMinutes minutes before completing.');
      }

      final burned = workout.level == 'Expert'
          ? workout.minutes * 10
          : workout.level == 'Intermediate'
              ? workout.minutes * 7
              : workout.minutes * 5;

      final logSnap = await transaction.get(logRef);
      final completedMap = {...workout.toMap(), 'completedAt': DateTime.now().toUtc().toIso8601String()};

      if (!logSnap.exists) {
        transaction.set(logRef, {
          'date': dateKey(),
          'caloriesIn': 0,
          'caloriesOut': burned,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
          'waterGlasses': 0,
          'foods': [],
          'workouts': [completedMap],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        final data = logSnap.data() as Map<String, dynamic>? ?? {};
        final workouts = List<dynamic>.from(data['workouts'] as List? ?? []);
        if (workouts.any((w) => (w as Map)['id'] == workout.id)) {
          transaction.update(sessionRef, {
            'completed': true,
            'completedAt': DateTime.now().toUtc().toIso8601String(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
        }
        final nextCalOut = ((data['caloriesOut'] as num?)?.toInt() ?? 0) + burned;
        if (nextCalOut > 10000) throw Exception('Daily workout calories exceeded.');
        workouts.add(completedMap);
        transaction.update(logRef, {
          'caloriesOut': nextCalOut,
          'workouts': workouts,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(sessionRef, {
        'completed': true,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

