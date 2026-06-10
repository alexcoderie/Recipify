import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:recipify/models/recipe.dart';
import 'package:recipify/providers/meal_log_provider.dart';
import 'package:recipify/providers/recipe_provider.dart';
import 'package:recipify/providers/user_profile_provider.dart';
import 'package:recipify/screens/recipe_detail_screen.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final _ingredientController = TextEditingController();

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final todayLog  = ref.read(todayLogProvider).value;
      final profile   = ref.read(userProfileProvider).value;
      if (todayLog == null || profile == null) return;

      ref.read(recipeTargetsProvider.notifier).state = {
        'calories': (profile.dailyCalorieGoal - todayLog.totalCalories)
            .clamp(0, double.infinity),
        'protein':  (profile.dailyProteinGoal - todayLog.totalProtein)
            .clamp(0, double.infinity),
        'carbs':    (profile.dailyCarbsGoal   - todayLog.totalCarbs)
            .clamp(0, double.infinity),
      };
    });
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isEmpty) return;
    ref.read(ingredientsProvider.notifier).update((list) => [...list, text]);
    _ingredientController.clear();
  }

  void _removeIngredient(int index) {
    ref.read(ingredientsProvider.notifier).update(
          (list) => [...list]..removeAt(index),
    );
  }

  Future<void> _generateRecipes() async {
    final ingredients = ref.read(ingredientsProvider);
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient')),
      );
      return;
    }

    ref.read(recipeLoadingProvider.notifier).state = true;
    ref.read(generatedRecipesProvider.notifier).state = [];

    try {
      final targets = ref.read(recipeTargetsProvider);
      final recipes = await generateRecipes(
        ingredients: ingredients,
        targets:     targets,
      );
      ref.read(generatedRecipesProvider.notifier).state = recipes;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating recipes: $e')),
        );
      }
    } finally {
      ref.read(recipeLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients    = ref.watch(ingredientsProvider);
    final targets        = ref.watch(recipeTargetsProvider);
    final recipes        = ref.watch(generatedRecipesProvider);
    final isLoading      = ref.watch(recipeLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  const Icon(LucideIcons.chefHat,
                      color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recipe Generator',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Find recipes that fit your macros',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Ingredients',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ingredientController,
                            onSubmitted: (_) => _addIngredient(),
                            decoration: InputDecoration(
                              hintText: 'Add ingredient...',
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                    color: Colors.green, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addIngredient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(48, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(LucideIcons.plus,
                              size: 20),
                        ),
                      ],
                    ),
                    if (ingredients.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ingredients
                            .asMap()
                            .entries
                            .map((e) => _IngredientChip(
                          label: e.value,
                          onRemove: () =>
                              _removeIngredient(e.key),
                        ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Macro Targets',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MacroTargetField(
                            label: 'Calories',
                            value: targets['calories']!
                                .toStringAsFixed(0),
                            onChanged: (v) => ref
                                .read(recipeTargetsProvider.notifier)
                                .update((t) => {
                              ...t,
                              'calories':
                              double.tryParse(v) ?? t['calories']!
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroTargetField(
                            label: 'Protein (g)',
                            value: targets['protein']!
                                .toStringAsFixed(0),
                            onChanged: (v) => ref
                                .read(recipeTargetsProvider.notifier)
                                .update((t) => {
                              ...t,
                              'protein':
                              double.tryParse(v) ?? t['protein']!
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MacroTargetField(
                            label: 'Carbs (g)',
                            value: targets['carbs']!
                                .toStringAsFixed(0),
                            onChanged: (v) => ref
                                .read(recipeTargetsProvider.notifier)
                                .update((t) => {
                              ...t,
                              'carbs':
                              double.tryParse(v) ?? t['carbs']!
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _generateRecipes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(LucideIcons.sparkles, size: 20),
                    label: Text(
                      isLoading
                          ? 'Generating...'
                          : 'Generate Recipes',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (recipes.isNotEmpty) ...[
                const Text(
                  'Suggested Recipes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...recipes.map((recipe) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecipeCard(recipe: recipe),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _IngredientChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _IngredientChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(LucideIcons.x,
                size: 14, color: Colors.green[700]),
          ),
        ],
      ),
    );
  }
}

class _MacroTargetField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _MacroTargetField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: Colors.green, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${recipe.cookTime} min',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${recipe.calories}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'cal',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MacroBadge(
                  label: 'Protein',
                  value: '${recipe.protein.toStringAsFixed(0)}g',
                  color: const Color(0xFFFFEDED),
                  textColor: Colors.red[600]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroBadge(
                  label: 'Carbs',
                  value: '${recipe.carbs.toStringAsFixed(0)}g',
                  color: const Color(0xFFFFFBEB),
                  textColor: Colors.amber[700]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroBadge(
                  label: 'Fat',
                  value: '${recipe.fat.toStringAsFixed(0)}g',
                  color: const Color(0xFFEFF6FF),
                  textColor: Colors.blue[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipe: recipe),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View Recipe'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style:
              TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}