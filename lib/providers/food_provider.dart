import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipify/models/food_product.dart';
import 'package:recipify/services/food_service.dart';

final foodServiceProvider = Provider<FoodService>((ref) => FoodService());

final scannedProductProvider =
FutureProvider.family<FoodProduct?, String>((ref, barcode) async {
  return ref.read(foodServiceProvider).fetchProductByBarcode(barcode);
});