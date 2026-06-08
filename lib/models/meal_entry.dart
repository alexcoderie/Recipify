class MealEntry {
  final String id;
  final String foodName;
  final String brand;
  final double grams;
  final DateTime loggedAt;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  MealEntry({
    required this.id,
    required this.foodName,
    required this.brand,
    required this.grams,
    required this.loggedAt,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  double get totalCalories => (calories * grams) / 100;

  double get totalProtein => (protein * grams) / 100;

  double get totalCarbs => (carbs * grams) / 100;

  double get totalFat => (fat * grams) / 100;

  Map<String, dynamic> toMap() => {
    'foodName': foodName,
    'brand': brand,
    'grams': grams,
    'loggedAt': loggedAt.toIso8601String(),
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'totalCalories': totalCalories,
    'totalProtein': totalProtein,
    'totalCarbs': totalCarbs,
    'totalFat': totalFat,
  };

  factory MealEntry.fromMap(String id, Map<String, dynamic> map) {
    return MealEntry(
      id: id,
      foodName: map['foodName'] ?? '',
      brand: map['brand'] ?? '',
      grams: (map['grams'] as num?)?.toDouble() ?? 100,
      loggedAt: DateTime.parse(map['loggedAt']),
      calories: (map['caloriesPer100g'] as num?)?.toDouble() ?? 0,
      protein: (map['proteinPer100g'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbsPer100g'] as num?)?.toDouble() ?? 0,
      fat: (map['fatPer100g'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DailyLog {
  final String date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final List<MealEntry> entries;

  DailyLog({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.entries,
  });
}
