import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../models/food.dart';
import '../providers/user_provider.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/food_log_provider.dart';
import '../theme/app_theme.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({Key? key}) : super(key: key);

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  bool _isLoading = false;
  
  Future<void> _generateMealPlan() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
      
      await mealPlanProvider.generateMealPlan(userProvider.user!);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New meal plan generated!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _logEntireMeal(String mealType, Meal meal) async {
    try {
      final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
      
      await foodLogProvider.addEntriesFromMeal(meal, mealType);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$mealType logged successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging meal: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealPlanProvider = Provider.of<MealPlanProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    
    final mealPlan = mealPlanProvider.mealPlan;
    final targetMacros = userProvider.getUserMacros();
    final isLoading = _isLoading || mealPlanProvider.isLoading;
    
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : mealPlan == null
              ? _buildNoMealPlanView()
              : _buildMealPlanView(mealPlan, targetMacros),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : _generateMealPlan,
        backgroundColor: isLoading ? Colors.grey : AppTheme.primaryColor,
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildNoMealPlanView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu,
            size: 80,
            color: AppTheme.textColorHint,
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          const Text(
            'No Meal Plan Generated',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingSmall),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
            child: Text(
              'Generate a meal plan based on your fitness goals and nutritional needs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textColorSecondary,
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          ElevatedButton.icon(
            onPressed: _generateMealPlan,
            icon: const Icon(Icons.add),
            label: const Text('Generate Meal Plan'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMealPlanView(MealPlan mealPlan, Map<String, double> targetMacros) {
    final currentMacros = mealPlan.calculateTotalMacros();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Macronutrient overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Plan Nutrition Overview',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNutrientColumn(
                        'Calories',
                        currentMacros['calories']?.toInt() ?? 0,
                        targetMacros['calories']?.toInt() ?? 0,
                        'kcal',
                        AppTheme.primaryColor,
                      ),
                      _buildNutrientColumn(
                        'Protein',
                        currentMacros['protein']?.toInt() ?? 0,
                        targetMacros['protein']?.toInt() ?? 0,
                        'g',
                        Colors.red,
                      ),
                      _buildNutrientColumn(
                        'Carbs',
                        currentMacros['carbs']?.toInt() ?? 0,
                        targetMacros['carbs']?.toInt() ?? 0,
                        'g',
                        Colors.blue,
                      ),
                      _buildNutrientColumn(
                        'Fats',
                        currentMacros['fats']?.toInt() ?? 0,
                        targetMacros['fats']?.toInt() ?? 0,
                        'g',
                        Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Meals
          const Text(
            'Your Meals',
            style: TextStyle(
              fontSize: AppTheme.fontSizeHeading,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // List of meals
          ...mealPlan.meals.map((meal) => _buildMealCard(meal)).toList(),
        ],
      ),
    );
  }
  
  Widget _buildNutrientColumn(String name, int value, int target, String unit, Color color) {
    final percentage = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.textColorSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingExtraSmall),
        Text(
          '$value',
          style: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$unit',
          style: const TextStyle(
            fontSize: AppTheme.fontSizeExtraSmall,
            color: AppTheme.textColorSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingExtraSmall),
        Text(
          '${(percentage * 100).toInt()}% of goal',
          style: const TextStyle(
            fontSize: AppTheme.fontSizeExtraSmall,
            color: AppTheme.textColorSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMealCard(Meal meal) {
    final macros = meal.calculateTotalMacros();
    
    String mealType = meal.name;
    if (mealType.toLowerCase() == 'breakfast') {
      mealType = 'Breakfast';
    } else if (mealType.toLowerCase() == 'lunch') {
      mealType = 'Lunch';
    } else if (mealType.toLowerCase() == 'dinner') {
      mealType = 'Dinner';
    } else {
      mealType = 'Snack';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Log this meal',
                  onPressed: () => _logEntireMeal(mealType, meal),
                ),
              ],
            ),
            
            // Macros summary
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingSmall,
                horizontal: AppTheme.spacingMedium,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColorLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${macros['calories']?.toInt() ?? 0} kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  Text('P: ${macros['protein']?.toInt() ?? 0}g'),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text('C: ${macros['carbs']?.toInt() ?? 0}g'),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text('F: ${macros['fats']?.toInt() ?? 0}g'),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Food items
            ...meal.items.map((item) => _buildFoodItem(item)).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFoodItem(MealItem item) {
    final macros = item.calculateMacros();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingExtraSmall),
      child: Row(
        children: [
          // Food color indicator by category
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: _getCategoryColor(item.food.category),
              shape: BoxShape.circle,
            ),
          ),
          
          // Food name and quantity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.food.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${item.quantity.toInt()}${item.food.servingUnit} (${item.food.category})',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Macros
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${macros['calories']?.toInt() ?? 0} kcal',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'P: ${macros['protein']?.toInt() ?? 0}g | C: ${macros['carbs']?.toInt() ?? 0}g | F: ${macros['fats']?.toInt() ?? 0}g',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textColorSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'protein':
        return Colors.red;
      case 'carbs':
        return Colors.blue;
      case 'fats':
        return Colors.amber;
      case 'vegetables':
        return Colors.green;
      case 'fruits':
        return Colors.purple;
      case 'dairy':
        return Colors.lightBlue;
      case 'supplements':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 