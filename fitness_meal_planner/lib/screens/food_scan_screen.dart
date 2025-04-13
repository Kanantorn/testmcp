import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/food_scan_provider.dart';
import '../providers/food_log_provider.dart';
import '../models/scanned_food.dart';
import '../models/food.dart';
import '../models/meal.dart';
import '../theme/app_theme.dart';

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({Key? key}) : super(key: key);

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final servingSizeController = TextEditingController(text: '100');
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    servingSizeController.dispose();
    super.dispose();
  }

  void _showFoodScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadiusLarge),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.borderRadiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan Food',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildScanOption(
                  context,
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<FoodScanProvider>(context, listen: false)
                        .pickImageAndScan(ImageSource.camera);
                  },
                ),
                _buildScanOption(
                  context,
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    Provider.of<FoodScanProvider>(context, listen: false)
                        .pickImageAndScan(ImageSource.gallery);
                  },
                ),
                _buildScanOption(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Barcode',
                  onTap: () {
                    Navigator.pop(context);
                    // In a real app, you'd implement barcode scanning here
                    // For now, we'll just mock it
                    Provider.of<FoodScanProvider>(context, listen: false)
                        .scanBarcode('123456789');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  void _addToMeal(ScannedFood scannedFood, String mealType) {
    final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
    
    double servingSize = 100;
    try {
      servingSize = double.parse(servingSizeController.text);
    } catch (e) {
      // Ignore and use default
    }
    
    // Create a Food object from ScannedFood
    final food = Food(
      id: DateTime.now().millisecondsSinceEpoch,
      name: scannedFood.name,
      calories: scannedFood.calories * (servingSize / 100),
      protein: scannedFood.protein * (servingSize / 100),
      carbs: scannedFood.carbs * (servingSize / 100),
      fats: scannedFood.fat * (servingSize / 100),
      servingSize: servingSize,
      servingUnit: scannedFood.servingUnit,
      category: 'Scanned Food',
    );
    
    // Add to the food log
    foodLogProvider.addEntry(food, servingSize, mealType);
    
    // Clear current scan
    Provider.of<FoodScanProvider>(context, listen: false).clearCurrentScan();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${scannedFood.name} to $mealType'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
      ),
    );
  }

  void _showAddToMealModal(ScannedFood scannedFood) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadiusLarge),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to Meal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: servingSizeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Serving Size (${scannedFood.servingUnit})',
                suffixText: scannedFood.servingUnit,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addToMeal(scannedFood, 'Breakfast');
                    },
                    child: const Text('Breakfast'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addToMeal(scannedFood, 'Lunch');
                    },
                    child: const Text('Lunch'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addToMeal(scannedFood, 'Dinner');
                    },
                    child: const Text('Dinner'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addToMeal(scannedFood, 'Snack');
                    },
                    child: const Text('Snack'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Scanner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scan'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Consumer<FoodScanProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildScanTab(provider),
              _buildHistoryTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showFoodScanOptions,
              child: const Icon(Icons.camera_alt),
            )
          : null,
    );
  }

  Widget _buildScanTab(FoodScanProvider provider) {
    if (provider.isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Analyzing food...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  provider.clearCurrentScan();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.currentScannedFood != null) {
      final food = provider.currentScannedFood!;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.currentImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                child: Image.file(
                  provider.currentImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              food.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Serving size: ${food.servingSize} ${food.servingUnit}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const Text(
              'Nutrition Facts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildNutritionRow('Calories', '${food.calories.toStringAsFixed(1)} kcal'),
            _buildNutritionRow('Protein', '${food.protein.toStringAsFixed(1)} g'),
            _buildNutritionRow('Carbs', '${food.carbs.toStringAsFixed(1)} g'),
            _buildNutritionRow('Fat', '${food.fat.toStringAsFixed(1)} g'),
            if (food.fiber > 0)
              _buildNutritionRow('Fiber', '${food.fiber.toStringAsFixed(1)} g'),
            if (food.sugar > 0)
              _buildNutritionRow('Sugar', '${food.sugar.toStringAsFixed(1)} g'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showAddToMealModal(food),
                child: const Text('Add to Meal'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  provider.clearCurrentScan();
                },
                child: const Text('Scan Another Food'),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Scan Food',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Take a photo of your food to get nutrition information',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showFoodScanOptions,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanning'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(FoodScanProvider provider) {
    if (provider.scannedFoodHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No scan history yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your scanned foods will appear here',
              style: TextStyle(color: AppTheme.textColorSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.scannedFoodHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final food = provider.scannedFoodHistory[index];
        return Card(
          elevation: 0,
          child: InkWell(
            onTap: () {
              // Set as current food and switch to first tab
              provider.clearCurrentScan();
              _tabController.animateTo(0);
              // Use a temporary variable
              final selectedFood = food;
              // Then set it after a short delay to allow the UI to update
              Future.microtask(() {
                final scanProvider = Provider.of<FoodScanProvider>(context, listen: false);
                // Call pickImageAndScan with the image but also set the food manually
                if (selectedFood.imageUrl != null) {
                  scanProvider.clearCurrentScan();
                  setState(() {
                    // This will trigger a refresh with the selected food data
                    scanProvider.setCurrentScannedFood(selectedFood);
                  });
                }
              });
            },
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: food.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                            child: Image.network(
                              food.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.fastfood,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.fastfood,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${food.calories.toStringAsFixed(0)} kcal | P: ${food.protein.toStringAsFixed(1)}g | C: ${food.carbs.toStringAsFixed(1)}g | F: ${food.fat.toStringAsFixed(1)}g',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _showAddToMealModal(food),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 