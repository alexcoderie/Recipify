import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_product.dart';

class FoodService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v3';

  Future<FoodProduct?> fetchProductByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/product/$barcode.json'),
        headers: {
          'User-Agent': 'Recipify/1.0 (alexcoderie5@gmail.com)',
        },
      );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);

      if (json['status'] == 0) return null;

      return FoodProduct.fromOpenFoodFacts(json);
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }
}