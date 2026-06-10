import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:recipify/models/recipe.dart';

final ingredientsProvider =
StateProvider<List<String>>((ref) => []);

final recipeTargetsProvider = StateProvider<Map<String, double>>((ref) => {
  'calories': 500,
  'protein':  40,
  'carbs':    50,
});

final generatedRecipesProvider =
StateProvider<List<Recipe>>((ref) => []);

final recipeLoadingProvider = StateProvider<bool>((ref) => false);

Future<List<Recipe>> generateRecipes({
  required List<String> ingredients,
  required Map<String, double> targets,
}) async {
  final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
      .httpsCallable('generateRecipes');

  final result = await callable.call({
    'ingredients': ingredients,
    'targets':     targets,
  });

  final data = List<Map<String, dynamic>>.from(
    (result.data as List).map((e) => Map<String, dynamic>.from(e)),
  );

  return data.map(Recipe.fromMap).toList();
}