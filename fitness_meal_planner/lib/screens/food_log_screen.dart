import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/food.dart';
import '../providers/food_log_provider.dart';
import '../providers/user_provider.dart';
import '../services/food_service.dart';
import '../theme/app_theme.dart';

class FoodLogScreen extends StatefulWidget {
  final int initialTab;
  
  const FoodLogScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('EEEE, MMMM d');
  final FoodService _foodService = FoodService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _changeDate(BuildContext context) async {
    final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
    final initialDate = foodLogProvider.selectedDate;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textColorPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null && pickedDate != initialDate) {
      foodLogProvider.setSelectedDate(pickedDate);
    }
  }
  
  Future<void> _showAddFoodDialog(BuildContext context) async {
    final List<Food> foods = await _foodService.getFoods();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FoodSearchBottomSheet(foods: foods),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final foodLogProvider = Provider.of<FoodLogProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    
    final selectedDate = foodLogProvider.selectedDate;
    final formattedDate = _dateFormat.format(selectedDate);
    final entriesByMeal = foodLogProvider.entriesByMealType;
    final consumedMacros = foodLogProvider.getTotalMacrosForSelectedDate();
    final targetMacros = userProvider.getUserMacros();
    
    return Scaffold(
      body: Column(
        children: [
          // Date selection bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    final newDate = selectedDate.subtract(const Duration(days: 1));
                    foodLogProvider.setSelectedDate(newDate);
                  },
                ),
                GestureDetector(
                  onTap: () => _changeDate(context),
                  child: Row(
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today, size: 16),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    final newDate = selectedDate.add(const Duration(days: 1));
                    foodLogProvider.setSelectedDate(newDate);
                  },
                ),
              ],
            ),
          ),
          
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textColorSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Food Log'),
              Tab(text: 'Nutrition'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Food Log Tab
                _buildFoodLogTab(entriesByMeal),
                
                // Nutrition Tab
                _buildNutritionTab(consumedMacros, targetMacros),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFoodDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildFoodLogTab(Map<String, List<FoodLogEntry>> entriesByMeal) {
    final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
    
    // Count total entries
    int totalEntries = 0;
    entriesByMeal.forEach((_, entries) => totalEntries += entries.length);
    
    return totalEntries > 0
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breakfast section
                if (entriesByMeal['Breakfast']!.isNotEmpty)
                  _buildMealSection('Breakfast', entriesByMeal['Breakfast']!),
                
                // Lunch section
                if (entriesByMeal['Lunch']!.isNotEmpty)
                  _buildMealSection('Lunch', entriesByMeal['Lunch']!),
                
                // Dinner section
                if (entriesByMeal['Dinner']!.isNotEmpty)
                  _buildMealSection('Dinner', entriesByMeal['Dinner']!),
                
                // Snack section
                if (entriesByMeal['Snack']!.isNotEmpty)
                  _buildMealSection('Snack', entriesByMeal['Snack']!),
                
                // Clear all button
                const SizedBox(height: AppTheme.spacingLarge),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear Food Log'),
                          content: const Text('Are you sure you want to clear all food entries for this day?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                foodLogProvider.clearEntriesForSelectedDate();
                                Navigator.of(context).pop();
                              },
                              child: const Text('Clear'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                    label: const Text('Clear All Entries', style: TextStyle(color: AppTheme.errorColor)),
                  ),
                ),
              ],
            ),
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.no_food,
                  size: 80,
                  color: AppTheme.textColorHint,
                ),
                
                const SizedBox(height: AppTheme.spacingMedium),
                
                const Text(
                  'No Food Logged Today',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingSmall),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                  child: Text(
                    'Add foods to your log to track your nutrition for the day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textColorSecondary,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingLarge),
                
                ElevatedButton.icon(
                  onPressed: () => _showAddFoodDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Food'),
                ),
              ],
            ),
          );
  }
  
  Widget _buildMealSection(String mealType, List<FoodLogEntry> entries) {
    final totalCalories = entries.fold<double>(
      0,
      (sum, entry) => sum + (entry.calculateMacros()['calories'] ?? 0),
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              mealType,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${totalCalories.toInt()} kcal',
              style: const TextStyle(
                color: AppTheme.textColorSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const Divider(),
        
        // Food entries
        ...entries.map((entry) => _buildFoodLogEntry(entry)).toList(),
      ],
    );
  }
  
  Widget _buildFoodLogEntry(FoodLogEntry entry) {
    final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
    final macros = entry.calculateMacros();
    
    return Dismissible(
      key: Key(entry.id),
      background: Container(
        color: AppTheme.errorColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingMedium),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        foodLogProvider.removeEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.food.name} removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                foodLogProvider.addEntry(
                  entry.food,
                  entry.quantity,
                  entry.mealType,
                );
              },
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Food color indicator
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: _getCategoryColor(entry.food.category),
                shape: BoxShape.circle,
              ),
            ),
            
            // Food details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.food.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${entry.quantity.toInt()} ${entry.food.servingUnit}',
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
      ),
    );
  }
  
  Widget _buildNutritionTab(Map<String, double> consumedMacros, Map<String, double> targetMacros) {
    // Calculate percentages of targets
    final caloriesPercent = targetMacros['calories'] != null && targetMacros['calories']! > 0
        ? (consumedMacros['calories'] ?? 0) / targetMacros['calories']!
        : 0.0;
    final proteinPercent = targetMacros['protein'] != null && targetMacros['protein']! > 0
        ? (consumedMacros['protein'] ?? 0) / targetMacros['protein']!
        : 0.0;
    final carbsPercent = targetMacros['carbs'] != null && targetMacros['carbs']! > 0
        ? (consumedMacros['carbs'] ?? 0) / targetMacros['carbs']!
        : 0.0;
    final fatsPercent = targetMacros['fats'] != null && targetMacros['fats']! > 0
        ? (consumedMacros['fats'] ?? 0) / targetMacros['fats']!
        : 0.0;
    
    // Calculate macro distribution percentages
    final totalConsumedCalories = consumedMacros['calories'] ?? 0;
    final proteinCalories = (consumedMacros['protein'] ?? 0) * 4; // 4 calories per gram
    final carbsCalories = (consumedMacros['carbs'] ?? 0) * 4; // 4 calories per gram
    final fatsCalories = (consumedMacros['fats'] ?? 0) * 9; // 9 calories per gram
    
    final proteinCaloriePercent = totalConsumedCalories > 0 ? proteinCalories / totalConsumedCalories : 0.0;
    final carbsCaloriePercent = totalConsumedCalories > 0 ? carbsCalories / totalConsumedCalories : 0.0;
    final fatsCaloriePercent = totalConsumedCalories > 0 ? fatsCalories / totalConsumedCalories : 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calories progress card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calories',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(consumedMacros['calories'] ?? 0).toInt()}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Text(
                        ' / ',
                        style: TextStyle(
                          fontSize: 28,
                          color: AppTheme.textColorSecondary,
                        ),
                      ),
                      Text(
                        '${(targetMacros['calories'] ?? 0).toInt()}',
                        style: const TextStyle(
                          fontSize: 28,
                          color: AppTheme.textColorSecondary,
                        ),
                      ),
                      const Text(
                        ' kcal',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  
                  // Progress bar
                  LinearProgressIndicator(
                    value: caloriesPercent.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingSmall),
                  
                  // Remaining text
                  Text(
                    'Remaining: ${((targetMacros['calories'] ?? 0) - (consumedMacros['calories'] ?? 0)).toInt()} kcal',
                    style: const TextStyle(
                      color: AppTheme.textColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Macronutrients card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Macronutrients',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  
                  // Protein progress
                  _buildMacroProgressItem(
                    'Protein',
                    consumedMacros['protein'] ?? 0,
                    targetMacros['protein'] ?? 0,
                    proteinPercent.clamp(0.0, 1.0),
                    Colors.red,
                    'g',
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  
                  // Carbs progress
                  _buildMacroProgressItem(
                    'Carbs',
                    consumedMacros['carbs'] ?? 0,
                    targetMacros['carbs'] ?? 0,
                    carbsPercent.clamp(0.0, 1.0),
                    Colors.blue,
                    'g',
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  
                  // Fats progress
                  _buildMacroProgressItem(
                    'Fats',
                    consumedMacros['fats'] ?? 0,
                    targetMacros['fats'] ?? 0,
                    fatsPercent.clamp(0.0, 1.0),
                    Colors.amber,
                    'g',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Macronutrient distribution card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Macronutrient Distribution',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  
                  // Distribution bar
                  Container(
                    height: 24,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (proteinCaloriePercent * 100).toInt(),
                          child: Container(color: Colors.red),
                        ),
                        Expanded(
                          flex: (carbsCaloriePercent * 100).toInt(),
                          child: Container(color: Colors.blue),
                        ),
                        Expanded(
                          flex: (fatsCaloriePercent * 100).toInt(),
                          child: Container(color: Colors.amber),
                        ),
                        // Fill any remaining space (due to rounding)
                        Expanded(
                          flex: 100 - (proteinCaloriePercent * 100).toInt() - 
                                 (carbsCaloriePercent * 100).toInt() - 
                                 (fatsCaloriePercent * 100).toInt(),
                          child: Container(color: Colors.grey[300]),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem(
                        'Protein',
                        '${(proteinCaloriePercent * 100).toInt()}%',
                        Colors.red,
                      ),
                      _buildLegendItem(
                        'Carbs',
                        '${(carbsCaloriePercent * 100).toInt()}%',
                        Colors.blue,
                      ),
                      _buildLegendItem(
                        'Fats',
                        '${(fatsCaloriePercent * 100).toInt()}%',
                        Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroProgressItem(String name, double consumed, double target, double percentage, Color color, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${consumed.toInt()} / ${target.toInt()} $unit',
              style: const TextStyle(
                color: AppTheme.textColorSecondary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingSmall),
        
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        
        const SizedBox(height: AppTheme.spacingExtraSmall),
        
        Text(
          '${(percentage * 100).toInt()}% of goal',
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String name, String percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
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

class FoodSearchBottomSheet extends StatefulWidget {
  final List<Food> foods;
  
  const FoodSearchBottomSheet({
    Key? key,
    required this.foods,
  }) : super(key: key);

  @override
  State<FoodSearchBottomSheet> createState() => _FoodSearchBottomSheetState();
}

class _FoodSearchBottomSheetState extends State<FoodSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FoodService _foodService = FoodService();
  
  List<Food> _filteredFoods = [];
  String _selectedMealType = 'Breakfast';
  String _searchQuery = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _filteredFoods = widget.foods;
    
    _searchController.addListener(() {
      _filterFoods(_searchController.text);
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterFoods(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });
    
    try {
      if (query.isEmpty) {
        _filteredFoods = widget.foods;
      } else {
        _filteredFoods = await _foodService.searchFoods(query);
      }
    } catch (e) {
      print('Error filtering foods: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showAddFoodDialog(Food food) async {
    double quantity = food.servingSize;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(food.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quantity input
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity (${food.servingUnit})',
                hintText: 'Enter amount',
              ),
              onChanged: (value) {
                try {
                  quantity = double.parse(value);
                } catch (e) {
                  // Invalid input, keep default
                }
              },
              controller: TextEditingController(text: food.servingSize.toString()),
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Meal type selection
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Meal Type',
              ),
              value: _selectedMealType,
              items: const [
                DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
                DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                DropdownMenuItem(value: 'Snack', child: Text('Snack')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMealType = value ?? 'Breakfast';
                });
              },
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Food info
            _buildNutrientInfo(
              'Calories:',
              '${food.calories} kcal per ${food.servingSize}${food.servingUnit}',
            ),
            _buildNutrientInfo(
              'Protein:',
              '${food.protein}g per ${food.servingSize}${food.servingUnit}',
            ),
            _buildNutrientInfo(
              'Carbs:',
              '${food.carbs}g per ${food.servingSize}${food.servingUnit}',
            ),
            _buildNutrientInfo(
              'Fats:',
              '${food.fats}g per ${food.servingSize}${food.servingUnit}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
              foodLogProvider.addEntry(food, quantity, _selectedMealType);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Add Food'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutrientInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColorSecondary,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Food',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search foods...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
          ),
          
          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
            child: Row(
              children: [
                _buildCategoryChip('All', null),
                _buildCategoryChip('Protein', 'protein'),
                _buildCategoryChip('Carbs', 'carbs'),
                _buildCategoryChip('Fats', 'fats'),
                _buildCategoryChip('Vegetables', 'vegetables'),
                _buildCategoryChip('Fruits', 'fruits'),
                _buildCategoryChip('Dairy', 'dairy'),
              ],
            ),
          ),
          
          // Food list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFoods.isEmpty
                    ? const Center(
                        child: Text('No foods found. Try a different search.'),
                      )
                    : ListView.builder(
                        itemCount: _filteredFoods.length,
                        itemBuilder: (context, index) {
                          final food = _filteredFoods[index];
                          return _buildFoodListItem(food);
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryChip(String label, String? category) {
    final selected = _searchQuery.toLowerCase() == (category ?? '').toLowerCase();
    
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (selected) {
          if (selected) {
            _searchController.text = category ?? '';
          } else {
            _searchController.text = '';
          }
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColorLight,
        checkmarkColor: AppTheme.primaryColor,
      ),
    );
  }
  
  Widget _buildFoodListItem(Food food) {
    final macros = {
      'calories': food.calories,
      'protein': food.protein,
      'carbs': food.carbs,
      'fats': food.fats,
    };
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getCategoryColor(food.category).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            food.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getCategoryColor(food.category),
            ),
          ),
        ),
      ),
      title: Text(
        food.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${food.servingSize} ${food.servingUnit} - ${food.category}',
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          color: AppTheme.textColorSecondary,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${macros['calories']?.toInt() ?? 0} kcal',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'P: ${macros['protein']?.toInt() ?? 0}g | C: ${macros['carbs']?.toInt() ?? 0}g | F: ${macros['fats']?.toInt() ?? 0}g',
            style: const TextStyle(
              fontSize: AppTheme.fontSizeExtraSmall,
              color: AppTheme.textColorSecondary,
            ),
          ),
        ],
      ),
      onTap: () => _showAddFoodDialog(food),
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