import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_config.dart';
import '../constants/enums.dart';
import '../models/custom_food.dart';
import '../models/daily_log.dart';
import '../models/feedback_log.dart';
import '../models/content_model.dart';
import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../utils/datetime_utils.dart';
import '../utils/health_profile_stats.dart';
import '../utils/input_validator.dart';
import '../utils/retryable_operation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // --- Collection References ---
  CollectionReference get _usersRef => _db.collection('users');

  Future<T> _withRetry<T>(String operationName, Future<T> Function() operation) {
    return RetryableOperation.execute<T>(
      operationName: operationName,
      operation: operation,
    );
  }

  // ── validation ────────────────────────────────────────────────────────────

  void _validateFoodItem(FoodItem food) {
    if (food.name.trim().isEmpty) {
      throw ArgumentError('Food name is required.');
    }

    // Use InputValidator for validation
    final nameError = InputValidator.validateFoodName(food.name);
    if (nameError != null) throw ArgumentError(nameError);

    final calError = InputValidator.validateCalories(food.calories.toString());
    if (calError != null) throw ArgumentError(calError);

    final values = [food.calories, food.protein, food.carbs, food.fat];
    if (values.any((v) => v < 0)) {
      throw ArgumentError('Food values must be non-negative.');
    }
    if (food.calories > AppConfig.maxSingleFoodCalories ||
        food.protein > AppConfig.maxSingleMacroGrams ||
        food.carbs > AppConfig.maxSingleMacroGrams ||
        food.fat > AppConfig.maxSingleMacroGrams) {
      throw ArgumentError('Food values exceed safe limits.');
    }
  }

  void _validateWorkout(WorkoutItem workout) {
    if (workout.id <= 0) throw ArgumentError('Workout id is invalid.');
    if (workout.title.trim().isEmpty) {
      throw ArgumentError('Workout title is required.');
    }
    if (workout.minutes < AppConfig.minWorkoutMinutes ||
        workout.minutes > AppConfig.maxWorkoutMinutes) {
      throw ArgumentError('Workout duration is out of range.');
    }
  }

  // ── Profile Operations ────────────────────────────────────────────────────

  Stream<UserProfile?> streamUserProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return UserProfile.fromMap(uid, snap.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Stream<List<UserProfile>> streamAllUsers() {
    return _usersRef.snapshots().map((snap) {
      return snap.docs
          .map((doc) =>
              UserProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // ── Admin Operations ──────────────────────────────────────────────────────

  Future<void> setAdminRole(String targetUid, bool promoteToAdmin) async {
    final callable = FirebaseFunctions.instance.httpsCallable('setAdminRole');
    await callable.call({
      'targetUid': targetUid,
      'role': promoteToAdmin ? UserRole.admin.value : UserRole.user.value,
    });
  }

  Future<void> deleteUserAccount(String targetUid) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
    await callable.call({'targetUid': targetUid});
  }

  Future<void> saveUserProfile(String uid, UserProfile profile) async {
    final validationError = HealthProfileValidator.validate(
      name: profile.name,
      birthMonth: profile.birthMonth ?? 0,
      birthYear: profile.birthYear ?? 0,
      height: profile.height,
      weight: profile.weight,
      targetWeight: profile.targetWeight,
      goal: profile.goal,
    );
    if (validationError != null) throw ArgumentError(validationError);
    await _withRetry('saveUserProfile', () {
      return _usersRef
          .doc(uid)
          .set(profile.toEditableMap(), SetOptions(merge: true));
    });
  }

  Future<void> updateLoginStreak(String uid) async {
    final now = DateTime.now();
    final userRef = _usersRef.doc(uid);
    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(userRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final currentStreak = (data['streak'] as int?) ?? 0;
      final rawLastLogin = data['lastLoginDate'] as String?;
      final nextStreak = calculateNextLoginStreak(
        currentStreak: currentStreak,
        rawLastLogin: rawLastLogin,
        now: now,
      );
      if (nextStreak == null) return;
      transaction.update(userRef, {
        'streak': nextStreak,
        'lastLoginDate': now.toUtc().toIso8601String(),
      });
    });
  }

  // ── Static helpers ────────────────────────────────────────────────────────

  static Map<String, int> calculateStats(double weight, double height, int age,
      String gender, String activityLevel, String goal) {
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

  static String bangkokDateKey([DateTime? dateTime]) {
    final source = (dateTime ?? DateTime.now()).toUtc();
    final bkk = source.add(const Duration(hours: AppConfig.bangkokUtcOffsetHours));
    return '${bkk.year.toString().padLeft(4, '0')}-'
        '${bkk.month.toString().padLeft(2, '0')}-'
        '${bkk.day.toString().padLeft(2, '0')}';
  }

  static String? _normalizeBangkokDateKey(String? rawDate) {
    if (rawDate == null) return null;
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return null;
    return bangkokDateKey(parsed);
  }

  static int? calculateNextLoginStreak({
    required int currentStreak,
    required String? rawLastLogin,
    DateTime? now,
  }) {
    final todayKey = bangkokDateKey(now);
    final lastKey = _normalizeBangkokDateKey(rawLastLogin);
    if (lastKey == todayKey) return null;
    int nextStreak = 1;
    if (lastKey != null) {
      final last = DateTime.parse('${lastKey}T00:00:00Z');
      final today = DateTime.parse('${todayKey}T00:00:00Z');
      final diff = today.difference(last).inDays;
      if (diff == 1) nextStreak = currentStreak > 0 ? currentStreak + 1 : 1;
    }
    return nextStreak;
  }

  static int requiredWorkoutMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return 0;
    return (totalMinutes * 0.6).ceil().clamp(1, totalMinutes);
  }

  static int calculateWorkoutCalories(WorkoutItem workout) {
    return workout.level == 'Expert'
        ? workout.minutes * 10
        : workout.level == 'Intermediate'
            ? workout.minutes * 7
            : workout.minutes * 5;
  }

  // ── Daily Log — Date keys ─────────────────────────────────────────────────

  static String dateKey([DateTime? dateTime]) {
    return DateTimeUtils.dateKey(dateTime ?? DateTimeUtils.now());
  }

  static String utcDateKey([DateTime? dateTime]) => bangkokDateKey(dateTime);

  DocumentReference _logRef(String uid, [String? key]) {
    return _usersRef.doc(uid).collection('daily_logs').doc(key ?? dateKey());
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<DailyLog?> streamDailyLog(String uid) {
    return _logRef(uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return DailyLog.fromMap(snap.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Stream<Map<int, WorkoutSessionState>> streamTodayWorkoutSessions(String uid) {
    return _usersRef
        .doc(uid)
        .collection('workout_sessions')
        .where('dateKey', isEqualTo: dateKey())
        .snapshots()
        .map((snap) {
      final sessions = <int, WorkoutSessionState>{};
      for (final doc in snap.docs) {
        final s = WorkoutSessionState.fromMap(doc.data());
        sessions[s.workoutId] = s;
      }
      return sessions;
    });
  }

  Stream<List<DailyLog>> streamDailyLogs(String uid, {int limit = 30}) {
    return _usersRef
        .doc(uid)
        .collection('daily_logs')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => DailyLog.fromMap(doc.data())).toList());
  }

  Stream<List<WorkoutVideo>> streamWorkoutVideos() {
    return _db
        .collection('workout_videos')
        .orderBy('id')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WorkoutVideo.fromMap(doc.data()))
            .where((video) => video.youtubeUrl.trim().isNotEmpty)
            .toList());
  }

  // ── Food CRUD ─────────────────────────────────────────────────────────────

  Future<void> addFood(String uid, FoodItem food) async {
    _validateFoodItem(food);
    // Ensure food has an ID
    if (food.id.isEmpty) food.id = _uuid.v4();
    final logRef = _logRef(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(logRef);
      final foodMap = food.toMap();
      if (!snap.exists) {
        tx.set(logRef, {
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
      final caloriesIn =
          ((data['caloriesIn'] as num?)?.toInt() ?? 0) + food.calories;
      if (caloriesIn > AppConfig.maxDailyCalories) {
        throw Exception('Daily calories exceed the allowed limit.');
      }
      foods.add(foodMap);
      tx.update(logRef, {
        'caloriesIn': caloriesIn,
        'protein': ((data['protein'] as num?)?.toInt() ?? 0) + food.protein,
        'carbs': ((data['carbs'] as num?)?.toInt() ?? 0) + food.carbs,
        'fat': ((data['fat'] as num?)?.toInt() ?? 0) + food.fat,
        'foods': foods,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Remove a food item by [foodId] from a specific day's log (default: today).
  Future<void> removeFood(String uid, String foodId,
      {String? forDateKey}) async {
    final logRef = _logRef(uid, forDateKey);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(logRef);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final foods = List<Map<String, dynamic>>.from(
        (data['foods'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final removed =
          foods.where((f) => (f['id'] as String?) == foodId).toList();
      if (removed.isEmpty) return; // already gone
      foods.removeWhere((f) => (f['id'] as String?) == foodId);

      // Recalculate totals from remaining list
      final totals = _sumFoods(foods);
      tx.update(logRef, {
        'foods': foods,
        'caloriesIn': totals['cal'],
        'protein': totals['protein'],
        'carbs': totals['carbs'],
        'fat': totals['fat'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Update a food item in-place (by id). Works for any day's log.
  Future<void> updateFoodItem(String uid, FoodItem updated,
      {String? forDateKey}) async {
    _validateFoodItem(updated);
    if (updated.id.isEmpty) {
      throw ArgumentError('FoodItem must have a non-empty id to update.');
    }
    final logRef = _logRef(uid, forDateKey);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(logRef);
      if (!snap.exists) throw Exception('Log not found.');
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final foods = List<Map<String, dynamic>>.from(
        (data['foods'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      final idx = foods.indexWhere((f) => (f['id'] as String?) == updated.id);
      if (idx < 0) throw Exception('Food item not found.');
      foods[idx] = updated.toMap();

      final totals = _sumFoods(foods);
      if (totals['cal']! > AppConfig.maxDailyCalories) {
        throw Exception('Daily calories exceed the allowed limit.');
      }
      tx.update(logRef, {
        'foods': foods,
        'caloriesIn': totals['cal'],
        'protein': totals['protein'],
        'carbs': totals['carbs'],
        'fat': totals['fat'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  static Map<String, int> _sumFoods(List<Map<String, dynamic>> foods) {
    int cal = 0, protein = 0, carbs = 0, fat = 0;
    for (final f in foods) {
      cal += (f['calories'] as num? ?? 0).toInt();
      protein += (f['protein'] as num? ?? 0).toInt();
      carbs += (f['carbs'] as num? ?? 0).toInt();
      fat += (f['fat'] as num? ?? 0).toInt();
    }
    return {'cal': cal, 'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  // ── Water ─────────────────────────────────────────────────────────────────

  Future<void> updateWater(String uid, int delta) async {
    if (![1, 2, 6, -1].contains(delta)) {
      throw ArgumentError('Unsupported water delta.');
    }
    final logRef = _logRef(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(logRef);
      if (!snap.exists) {
        if (delta <= 0) return;
        tx.set(logRef, {
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
      if (next > AppConfig.maxDailyWaterGlasses) {
        throw Exception('Daily water exceeds the allowed limit.');
      }
      tx.update(logRef,
          {'waterGlasses': next, 'lastUpdated': FieldValue.serverTimestamp()});
    });
  }

  /// Set water to an absolute value (for retroactive edits).
  Future<void> setWater(String uid, int glasses, {String? forDateKey}) async {
    if (glasses < 0 || glasses > AppConfig.maxDailyWaterGlasses) {
      throw ArgumentError('Water glasses out of range.');
    }
    final logRef = _logRef(uid, forDateKey);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(logRef);
      if (!snap.exists) throw Exception('Log not found for that date.');
      tx.update(logRef, {
        'waterGlasses': glasses,
        'lastUpdated': FieldValue.serverTimestamp()
      });
    });
  }

  // ── Workout ───────────────────────────────────────────────────────────────

  Future<void> startWorkoutSession(String uid, WorkoutItem workout) async {
    _validateWorkout(workout);
    final sessionRef = _usersRef
        .doc(uid)
        .collection('workout_sessions')
        .doc(workout.id.toString());
        
    final startedAtIso = DateTime.now().toUtc().toIso8601String();
    
    await _withRetry('startWorkoutSession', () {
      return sessionRef.set({
        'workoutId': workout.id,
        'title': workout.title,
        'level': workout.level,
        'type': workout.type,
        'minutes': workout.minutes,
        'dateKey': dateKey(),
        'startedAt': startedAtIso,
        'completed': false,
        'completedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> finishWorkout(String uid, WorkoutItem workout) async {
    _validateWorkout(workout);
    final logRef = _logRef(uid);
    final sessionRef = _usersRef
        .doc(uid)
        .collection('workout_sessions')
        .doc(workout.id.toString());

    await _db.runTransaction((tx) async {
      final sessionSnap = await tx.get(sessionRef);
      if (!sessionSnap.exists) throw Exception('Workout session not started.');
      final sessionData = sessionSnap.data() ?? <String, dynamic>{};
      final startedAt =
          DateTime.tryParse(sessionData['startedAt'] as String? ?? '');
      if (sessionData['dateKey'] != dateKey() || startedAt == null) {
        throw Exception('Workout session is no longer valid.');
      }
      if (sessionData['completed'] == true) {
        throw Exception(
            'Workout session already completed. Start a new session.');
      }
      final requiredMinutes = requiredWorkoutMinutes(workout.minutes);
      final elapsed = DateTime.now().difference(startedAt).inMinutes;
      if (elapsed < requiredMinutes) {
        throw Exception(
            'Need at least $requiredMinutes minutes before completing.');
      }
      final burned = calculateWorkoutCalories(workout);
      final logSnap = await tx.get(logRef);
      final completedMap = {
        ...workout.toMap(),
        'completedAt': DateTime.now().toUtc().toIso8601String()
      };
      if (!logSnap.exists) {
        tx.set(logRef, {
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
        final nextCalOut =
            ((data['caloriesOut'] as num?)?.toInt() ?? 0) + burned;
        if (nextCalOut > AppConfig.maxDailyWorkoutCalories) {
          throw Exception('Daily workout calories exceeded.');
        }
        workouts.add(completedMap);
        tx.update(logRef, {
          'caloriesOut': nextCalOut,
          'workouts': workouts,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      tx.update(sessionRef, {
        'completed': true,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Stream all completed workout sessions (for history screen).
  Stream<List<Map<String, dynamic>>> streamWorkoutSessions(String uid,
      {int limit = 50}) {
    return _usersRef
        .doc(uid)
        .collection('workout_sessions')
        .where('completed', isEqualTo: true)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  // ── Recent Foods ──────────────────────────────────────────────────────────

  Future<List<FoodItem>> getRecentUniqueFoods(String uid) async {
    final snapshot = await _usersRef
        .doc(uid)
        .collection('daily_logs')
        .orderBy('date', descending: true)
        .limit(7)
        .get();
    final List<FoodItem> recentFoods = [];
    final Set<String> uniqueNames = {};
    for (final doc in snapshot.docs) {
      final log = DailyLog.fromMap(doc.data());
      for (final food in log.foods) {
        if (!uniqueNames.contains(food.name.toLowerCase())) {
          recentFoods.add(food);
          uniqueNames.add(food.name.toLowerCase());
        }
      }
    }
    return recentFoods.take(10).toList();
  }

  // ── Weight Logs ───────────────────────────────────────────────────────────

  CollectionReference _weightLogsRef(String uid) =>
      _usersRef.doc(uid).collection('weight_logs');

  Future<void> logWeight(String uid, double weightKg,
      {String? note, String? forDateKey}) async {
    if (weightKg <= 0 || weightKg > 500) {
      throw ArgumentError('Weight out of range.');
    }
    final key = forDateKey ?? dateKey();
    final log = WeightLog(date: key, weightKg: weightKg, note: note);
    await _withRetry('logWeight', () => _weightLogsRef(uid).doc(key).set(log.toMap()));
  }

  Future<void> deleteWeightLog(String uid, String forDateKey) async {
    await _weightLogsRef(uid).doc(forDateKey).delete();
  }

  Stream<List<WeightLog>> streamWeightLogs(String uid, {int limit = 30}) {
    return _weightLogsRef(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WeightLog.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ── Custom Foods ──────────────────────────────────────────────────────────

  CollectionReference _customFoodsRef(String uid) =>
      _usersRef.doc(uid).collection('custom_foods');

  Stream<List<CustomFood>> streamCustomFoods(String uid) {
    return _customFoodsRef(uid)
        .orderBy('isFavorite', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                CustomFood.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<String> saveCustomFood(String uid, CustomFood food) async {
    if (food.name.trim().isEmpty) throw ArgumentError('Food name is required.');
    final id = food.id.isNotEmpty ? food.id : _uuid.v4();
    await _withRetry('saveCustomFood', () {
      return _customFoodsRef(uid)
          .doc(id)
          .set(food.toMap(), SetOptions(merge: true));
    });
    return id;
  }

  Future<void> deleteCustomFood(String uid, String foodId) async {
    await _customFoodsRef(uid).doc(foodId).delete();
  }

  Future<void> toggleFavorite(String uid, String foodId,
      {required bool isFavorite}) async {
    await _withRetry('toggleFavorite', () {
      return _customFoodsRef(uid).doc(foodId).update({'isFavorite': isFavorite});
    });
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  Future<void> submitFeedback(FeedbackLog log) async {
    final docId = _uuid.v4();
    await _withRetry('submitFeedback', () => _db.collection('feedback').doc(docId).set(log.toMap()));
  }

  Stream<List<FeedbackLog>> streamAllFeedback() {
    return _db
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FeedbackLog.fromMap(doc.id, doc.data()))
            .toList());
  }
}
