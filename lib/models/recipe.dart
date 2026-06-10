class Recipe {
  final String name;
  final int cookTime;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> ingredients;
  final List<String> steps;

  Recipe({
    required this.name,
    required this.cookTime,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) => Recipe(
    name:        map['name']        ?? '',
    cookTime:    (map['cookTime']   as num?)?.toInt() ?? 0,
    calories:    (map['calories']   as num?)?.toInt() ?? 0,
    protein:     (map['protein']    as num?)?.toDouble() ?? 0,
    carbs:       (map['carbs']      as num?)?.toDouble() ?? 0,
    fat:         (map['fat']        as num?)?.toDouble() ?? 0,
    ingredients: List<String>.from(map['ingredients'] ?? []),
    steps:       List<String>.from(map['steps'] ?? []),
  );
}