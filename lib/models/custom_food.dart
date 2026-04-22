class CustomFood {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final double servingSize;
  final String servingUnit;
  bool isFavorite;

  CustomFood({
    required this.id,
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.servingSize = 100,
    this.servingUnit = 'g',
    this.isFavorite = false,
  });

  factory CustomFood.fromMap(String id, Map<String, dynamic> map) {
    return CustomFood(
      id: id,
      name: map['name'] as String? ?? '',
      calories: (map['calories'] as num? ?? 0).toInt(),
      protein: (map['protein'] as num? ?? 0).toInt(),
      carbs: (map['carbs'] as num? ?? 0).toInt(),
      fat: (map['fat'] as num? ?? 0).toInt(),
      servingSize: (map['servingSize'] as num? ?? 100).toDouble(),
      servingUnit: map['servingUnit'] as String? ?? 'g',
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'isFavorite': isFavorite,
    };
  }

  /// Scale macros by [multiplier] servings
  CustomFood scaled(double multiplier) {
    return CustomFood(
      id: id,
      name: name,
      calories: (calories * multiplier).round(),
      protein: (protein * multiplier).round(),
      carbs: (carbs * multiplier).round(),
      fat: (fat * multiplier).round(),
      servingSize: servingSize,
      servingUnit: servingUnit,
      isFavorite: isFavorite,
    );
  }
}
