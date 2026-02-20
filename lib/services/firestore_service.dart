
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/daily_log.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Collection References ---
  CollectionReference get _usersRef => _db.collection('users');

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
    await _usersRef.doc(uid).set(profile.toMap(), SetOptions(merge: true));
  }

  // Update Login Streak
  Future<void> updateLoginStreak(String uid, UserProfile profile) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    bool shouldUpdate = false;
    
    if (profile.lastLoginDate != null) {
      final lastLogin = DateTime(
        profile.lastLoginDate!.year, 
        profile.lastLoginDate!.month, 
        profile.lastLoginDate!.day
      );
      final difference = today.difference(lastLogin).inDays;
      
      if (difference == 0) return; // Already logged in today
      
      if (difference == 1) {
        // Logged in yesterday
        profile.streak += 1;
      } else {
        // Missed one or more days
        profile.streak = 1;
      }
      shouldUpdate = true;
    } else {
      // First time logging in
      profile.streak = 1;
      shouldUpdate = true;
    }
    
    if (shouldUpdate) {
      profile.lastLoginDate = now;
      await saveUserProfile(uid, profile);
      print('Streak updated for $uid: ${profile.streak}');
    }
  }
  
  // TDEE Calculation Helper (Static)
  static Map<String, int> calculateStats(double weight, double height, int age, String gender, String activityLevel, String goal) {
     // Mifflin-St Jeor Equation
    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    bmr += (gender == 'male' ? 5 : -161);
    
    final activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725
    };
    
    double tdeeDouble = bmr * (activityMultipliers[activityLevel] ?? 1.2);
    int tdee = tdeeDouble.round();
    
    // Adjust for Goal
    int targetCalories = tdee;
    if (goal == 'lose') {
      targetCalories = tdee - 500;
    } else if (goal == 'gain') {
      targetCalories = tdee + 300;
    }

    // Ensure safe minimum
    if (targetCalories < 1200) targetCalories = 1200;

    // Macros (approximate split)
    int targetProtein = (weight * 2).round();
    int targetFat = ((targetCalories * 0.25) / 9).round();
    int remainingCals = targetCalories - (targetProtein * 4) - (targetFat * 9);
    int targetCarbs = (remainingCals / 4).round();
    
    if (targetCarbs < 0) targetCarbs = 0;
    
    // Water goal (approx 30ml per kg)
    int targetWaterGlasses = ((weight * 30) / 250).round();
    if (targetWaterGlasses < 6) targetWaterGlasses = 6;
    
    return {
      'tdee': tdee,
      'targetCalories': targetCalories,
      'targetProtein': targetProtein,
      'targetCarbs': targetCarbs,
      'targetFat': targetFat,
      'targetWaterGlasses': targetWaterGlasses,
    };
  }

  // --- Daily Log Operations ---
  // New Structure: /users/{uid}/daily_logs/{YYYY-MM-DD}

  DocumentReference _getTodayLogRef(String uid) {
    String todayStr = DateTime.now().toIso8601String().split('T')[0];
    return _usersRef.doc(uid).collection('daily_logs').doc(todayStr);
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
        transaction.set(logRef, newLog.toMap());
      } else {
        Map data = snapshot.data() as Map;
        int currentCals = data['caloriesIn'] ?? 0;
        int currentProtein = data['protein'] ?? 0;
        int currentCarbs = data['carbs'] ?? 0;
        int currentFat = data['fat'] ?? 0;

        transaction.update(logRef, {
          'caloriesIn': currentCals + food.calories,
          'protein': currentProtein + food.protein,
          'carbs': currentCarbs + food.carbs,
          'fat': currentFat + food.fat,
          'foods': FieldValue.arrayUnion([food.toMap()]),
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<void> updateWater(String uid, int delta) async {
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
          transaction.set(logRef, newLog.toMap());
        }
      } else {
        int currentWater = (snapshot.data() as Map)['waterGlasses'] ?? 0;
        int newValue = currentWater + delta;
        if(newValue < 0) newValue = 0;
        
        transaction.update(logRef, {
          'waterGlasses': newValue,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  Future<void> finishWorkout(String uid, WorkoutItem workout) async {
    DocumentReference logRef = _getTodayLogRef(uid);

    final snapshot = await logRef.get();
    if (!snapshot.exists) {
      final newLog = DailyLog(
          date: logRef.id,
          caloriesIn: 0,
          waterGlasses: 0,
          foods: [],
          workouts: [workout],
          lastUpdated: DateTime.now(),
        );
      await logRef.set(newLog.toMap());
    } else {
      await logRef.update({
        'workouts': FieldValue.arrayUnion([workout.toMap()]),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
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
          .map((doc) => DailyLog.fromMap(doc.data() as Map<String, dynamic>))
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
}
