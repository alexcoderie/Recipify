class FoodProduct {
  final String barcode;
  final String name;
  final String brand;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  FoodProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodProduct.fromOpenFoodFacts(Map<String, dynamic> json) {
    final product = json['product'] ?? {};
    final nutriments = product['nutriments'] ?? {};

    return FoodProduct(
      barcode: product['code'] ?? '',
      name: product['product_name'] ?? 'Unknown Product',
      brand: product['brands'] ?? 'Unknown Brand',
      servingSize: '100g',
      calories: (nutriments['energy-kcal_100g'] as num?)?.toDouble()
          ?? 0,
      protein: (nutriments['proteins_100g'] as num?)?.toDouble()
          ?? 0,
      carbs: (nutriments['carbohydrates_100g'] as num?)?.toDouble()
          ?? 0,
      fat: (nutriments['fat_100g'] as num?)?.toDouble()
          ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'barcode': barcode,
    'name': name,
    'brand': brand,
    'servingSize': servingSize,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
}