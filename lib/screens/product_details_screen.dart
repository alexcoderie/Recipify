import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:recipify/models/food_product.dart';
import 'package:recipify/models/meal_entry.dart';
import 'package:recipify/providers/auth_provider.dart';
import 'package:recipify/providers/food_provider.dart';
import 'package:recipify/providers/user_profile_provider.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String barcode;

  const ProductDetailsScreen({super.key, required this.barcode});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _servingSizeController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  bool _initialized = false;

  void _initControllers(FoodProduct product) {
    if (_initialized) return;
    _nameController = TextEditingController(text: product.name);
    _brandController = TextEditingController(text: product.brand);
    _servingSizeController = TextEditingController(text: product.servingSize);
    _caloriesController = TextEditingController(
      text: product.calories.toStringAsFixed(0),
    );
    _proteinController = TextEditingController(
      text: product.protein.toStringAsFixed(1),
    );
    _carbsController = TextEditingController(
      text: product.carbs.toStringAsFixed(1),
    );
    _fatController = TextEditingController(
      text: product.fat.toStringAsFixed(1),
    );
    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _brandController.dispose();
      _servingSizeController.dispose();
      _caloriesController.dispose();
      _proteinController.dispose();
      _carbsController.dispose();
      _fatController.dispose();
    }
    super.dispose();
  }

  void _saveToDiary(FoodProduct product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LogMealSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(scannedProductProvider(widget.barcode));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: productAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.green)),
        error: (e, _) => _ErrorView(
          message: 'Failed to load product',
          onBack: () => Navigator.of(context).pop(),
        ),
        data: (product) {
          if (product == null) {
            return _ErrorView(
              message: 'Product not found.\nTry scanning again.',
              onBack: () => Navigator.of(context).pop(),
            );
          }

          _initControllers(product);

          return Column(
            children: [
              Container(
                color: Colors.green,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            LucideIcons.arrowLeft,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Text(
                          'Product Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Product card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _isEditing
                                          ? TextField(
                                              controller: _nameController,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F2937),
                                              ),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.only(
                                                  bottom: 4,
                                                ),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.green,
                                                        width: 2,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color: Colors.green,
                                                        width: 2,
                                                      ),
                                                    ),
                                              ),
                                            )
                                          : Text(
                                              _nameController.text,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _brandController.text,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isEditing
                                        ? LucideIcons.check
                                        : LucideIcons.pencil,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _isEditing = !_isEditing),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Serving Size',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _isEditing
                                      ? TextField(
                                          controller: _servingSizeController,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.only(
                                              bottom: 2,
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.green,
                                              ),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.green,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          _servingSizeController.text,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Calories',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 15,
                                    ),
                                  ),
                                  _isEditing
                                      ? SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: _caloriesController,
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.green,
                                                      width: 2,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          _caloriesController.text,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.2,
                              children: [
                                _MacroCard(
                                  label: 'Protein',
                                  controller: _proteinController,
                                  color: const Color(0xFFFFEDED),
                                  textColor: Colors.red[600]!,
                                  isEditing: _isEditing,
                                ),
                                _MacroCard(
                                  label: 'Carbs',
                                  controller: _carbsController,
                                  color: const Color(0xFFFFFBEB),
                                  textColor: Colors.amber[700]!,
                                  isEditing: _isEditing,
                                ),
                                _MacroCard(
                                  label: 'Fat',
                                  controller: _fatController,
                                  color: const Color(0xFFEFF6FF),
                                  textColor: Colors.blue[600]!,
                                  isEditing: _isEditing,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _saveToDiary(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Save to Diary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color color;
  final Color textColor;
  final bool isEditing;

  const _MacroCard({
    required this.label,
    required this.controller,
    required this.color,
    required this.textColor,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 2),
          isEditing
              ? TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: textColor, width: 1),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: textColor, width: 2),
                    ),
                    suffix: Text(
                      'g',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ),
                )
              : Text(
                  '${controller.text}g',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _ErrorView({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.packageX, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogMealSheet extends ConsumerStatefulWidget {
  final FoodProduct product;

  const _LogMealSheet({required this.product});

  @override
  ConsumerState<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<_LogMealSheet> {
  double _grams = 100;
  bool _isLoading = false;
  final _gramsController = TextEditingController(text: '100');

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final grams = double.tryParse(_gramsController.text);
    if (grams == null || grams <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider)!;
      final entry = MealEntry(
        id: '',
        foodName: widget.product.name,
        brand: widget.product.brand,
        grams: _grams,
        loggedAt: DateTime.now(),
        calories: widget.product.calories,
        protein: widget.product.protein,
        carbs: widget.product.carbs,
        fat: widget.product.fat,
      );

      await ref.read(firestoreServiceProvider).logMeal(userId, entry);

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} added to diary'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging meal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Live macro preview as user types
    final grams = double.tryParse(_gramsController.text) ?? 0;
    final calories = (widget.product.calories * grams / 100);
    final protein = (widget.product.protein * grams / 100);
    final carbs = (widget.product.carbs * grams / 100);
    final fat = (widget.product.fat * grams / 100);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.product.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.product.brand,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Grams input
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _gramsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '100',
                      ),
                      onChanged: (_) => setState(() {}), // rebuild preview
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'g',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live macro preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroPreview(
                    label: 'Calories',
                    value: calories.toStringAsFixed(0),
                    unit: 'kcal',
                    color: Colors.green[700]!,
                  ),
                  _MacroPreview(
                    label: 'Protein',
                    value: protein.toStringAsFixed(1),
                    unit: 'g',
                    color: Colors.red[600]!,
                  ),
                  _MacroPreview(
                    label: 'Carbs',
                    value: carbs.toStringAsFixed(1),
                    unit: 'g',
                    color: Colors.amber[700]!,
                  ),
                  _MacroPreview(
                    label: 'Fat',
                    value: fat.toStringAsFixed(1),
                    unit: 'g',
                    color: Colors.blue[600]!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add to Diary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MacroPreview extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MacroPreview({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
