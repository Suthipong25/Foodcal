/// แหล่งที่มาของข้อมูลโภชนาการ
enum NutritionSource {
  /// ข้อมูลจากฐานข้อมูล Open Food Facts (แม่นยำ)
  database,

  /// ค่าประมาณจาก Gemini AI
  aiEstimate,

  /// กรอกด้วยตนเอง
  manual,
}

extension NutritionSourceX on NutritionSource {
  String get label {
    switch (this) {
      case NutritionSource.database:
        return 'ฐานข้อมูล';
      case NutritionSource.aiEstimate:
        return 'ค่าประมาณ';
      case NutritionSource.manual:
        return 'กรอกเอง';
    }
  }

  String get toStringValue {
    switch (this) {
      case NutritionSource.database:
        return 'database';
      case NutritionSource.aiEstimate:
        return 'ai_estimate';
      case NutritionSource.manual:
        return 'manual';
    }
  }

  static NutritionSource fromString(String? value) {
    switch (value) {
      case 'database':
        return NutritionSource.database;
      case 'manual':
        return NutritionSource.manual;
      default:
        return NutritionSource.aiEstimate;
    }
  }
}

/// ผลลัพธ์การค้นหาข้อมูลโภชนาการ
class NutritionResult {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  /// หน่วยของ serving (เช่น "1 จาน (~300g)", "1 ชิ้น (~150g)")
  final String servingLabel;

  /// แหล่งที่มา
  final NutritionSource source;

  const NutritionResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servingLabel = '1 serving',
    required this.source,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'servingLabel': servingLabel,
        'nutritionSource': source.toStringValue,
      };

  factory NutritionResult.fromMap(Map<String, dynamic> map) {
    return NutritionResult(
      name: map['name'] as String? ?? '',
      calories: (map['calories'] as num? ?? 0).toInt(),
      protein: (map['protein'] as num? ?? 0).toInt(),
      carbs: (map['carbs'] as num? ?? 0).toInt(),
      fat: (map['fat'] as num? ?? 0).toInt(),
      servingLabel: map['servingLabel'] as String? ?? '1 serving',
      source: NutritionSourceX.fromString(map['nutritionSource'] as String?),
    );
  }

  NutritionResult copyWith({
    String? name,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    String? servingLabel,
    NutritionSource? source,
  }) {
    return NutritionResult(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servingLabel: servingLabel ?? this.servingLabel,
      source: source ?? this.source,
    );
  }
}
