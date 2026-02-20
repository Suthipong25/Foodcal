
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
    return UserProfile(
      uid: uid,
      name: map['name'] ?? '',
      gender: map['gender'] ?? 'male',
      age: (map['age'] ?? 25).toInt(),
      height: (map['height'] ?? 170).toDouble(),
      weight: (map['weight'] ?? 60).toDouble(),
      activityLevel: map['activityLevel'] ?? 'moderate',
      goal: map['goal'] ?? 'maintain',
      tdee: (map['tdee'] ?? 2000).toInt(),
      targetCalories: (map['targetCalories'] ?? 2000).toInt(),
      targetProtein: (map['targetProtein'] ?? 100).toInt(),
      targetCarbs: (map['targetCarbs'] ?? 250).toInt(),
      targetFat: (map['targetFat'] ?? 60).toInt(),
      targetWaterGlasses: (map['targetWaterGlasses'] ?? 8).toInt(),
      streak: (map['streak'] ?? 0).toInt(),
      joinedDate: DateTime.parse(map['joinedDate'] ?? DateTime.now().toIso8601String()),
      lastLoginDate: map['lastLoginDate'] != null ? DateTime.parse(map['lastLoginDate']) : null,
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
}
