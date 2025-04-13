import '../models/food.dart';
import '../models/meal.dart';
import '../models/user.dart';
import '../mcp/sequential_thinking_runner.dart';
import 'food_service.dart';

class MCPService {
  final FoodService foodService;

  MCPService({required this.foodService});

  Future<MealPlan> generateMealPlan(User user) async {
    List<Food> foods = await foodService.getFoods();
    
    // Prepare user profile for MCP
    Map<String, dynamic> userProfile = user.toJson();
    
    // Get target macros for the user
    Map<String, double> targetMacros = user.calculateMacros();
    
    // Convert foods to JSON format
    List<Map<String, dynamic>> availableFoods = foods.map((f) => f.toJson()).toList();
    
    try {
      // Generate meal plan using Sequential Thinking
      Map<String, dynamic> result = await MCPSequentialThinkingRunner.generateMealPlan(
        userProfile: userProfile,
        targetMacros: targetMacros,
        availableFoods: availableFoods,
      );
      
      // Extract meal plan data
      Map<String, dynamic> mealPlanData = result['meal_plan'];
      
      // Create a new meal plan object
      MealPlan mealPlan = MealPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        meals: (mealPlanData['meals'] as List)
            .map((meal) => Meal.fromJson(meal, foods))
            .toList(),
      );
      
      return mealPlan;
    } catch (e) {
      print('Error generating meal plan with MCP: $e');
      // Fall back to default plan generation
      return await generateFallbackMealPlan(user);
    }
  }
  
  // Fallback method to generate a meal plan if MCP fails
  Future<MealPlan> generateFallbackMealPlan(User user) async {
    List<Food> foods = await foodService.getFoods();
    Map<String, double> targetMacros = user.calculateMacros();
    
    // Create a basic structure for meals
    List<Meal> meals = [
      _createMeal('Breakfast', foods, targetMacros, 0.25),
      _createMeal('Lunch', foods, targetMacros, 0.35),
      _createMeal('Dinner', foods, targetMacros, 0.30),
      _createMeal('Snack', foods, targetMacros, 0.10),
    ];
    
    return MealPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      meals: meals,
    );
  }
  
  // Helper method to create a single meal with approximate macros
  Meal _createMeal(String name, List<Food> foods, Map<String, double> targetMacros, double mealRatio) {
    // Calculate target macros for this meal
    double targetCalories = (targetMacros['calories'] ?? 2000) * mealRatio;
    double targetProtein = (targetMacros['protein'] ?? 150) * mealRatio;
    double targetCarbs = (targetMacros['carbs'] ?? 200) * mealRatio;
    double targetFats = (targetMacros['fats'] ?? 70) * mealRatio;
    
    List<MealItem> items = [];
    double currentCalories = 0;
    double currentProtein = 0;
    double currentCarbs = 0;
    double currentFats = 0;
    
    // Categorize foods
    List<Food> proteinFoods = foods.where((f) => f.category == 'protein').toList();
    List<Food> carbFoods = foods.where((f) => f.category == 'carbs').toList();
    List<Food> fatFoods = foods.where((f) => f.category == 'fats').toList();
    List<Food> veggieFoods = foods.where((f) => f.category == 'vegetables').toList();
    
    // Add protein source
    if (proteinFoods.isNotEmpty) {
      Food proteinFood = proteinFoods[DateTime.now().millisecond % proteinFoods.length];
      double quantity = (targetProtein / proteinFood.protein) * proteinFood.servingSize;
      quantity = quantity.clamp(proteinFood.servingSize * 0.5, proteinFood.servingSize * 2);
      
      MealItem item = MealItem(food: proteinFood, quantity: quantity);
      items.add(item);
      
      Map<String, double> macros = item.calculateMacros();
      currentProtein += macros['protein'] ?? 0;
      currentCarbs += macros['carbs'] ?? 0;
      currentFats += macros['fats'] ?? 0;
      currentCalories += macros['calories'] ?? 0;
    }
    
    // Add carb source
    if (carbFoods.isNotEmpty) {
      Food carbFood = carbFoods[DateTime.now().microsecond % carbFoods.length];
      double quantity = (targetCarbs / carbFood.carbs) * carbFood.servingSize;
      quantity = quantity.clamp(carbFood.servingSize * 0.5, carbFood.servingSize * 2);
      
      MealItem item = MealItem(food: carbFood, quantity: quantity);
      items.add(item);
      
      Map<String, double> macros = item.calculateMacros();
      currentProtein += macros['protein'] ?? 0;
      currentCarbs += macros['carbs'] ?? 0;
      currentFats += macros['fats'] ?? 0;
      currentCalories += macros['calories'] ?? 0;
    }
    
    // Add fat source
    if (fatFoods.isNotEmpty) {
      Food fatFood = fatFoods[DateTime.now().second % fatFoods.length];
      double quantity = (targetFats / fatFood.fats) * fatFood.servingSize;
      quantity = quantity.clamp(fatFood.servingSize * 0.2, fatFood.servingSize * 1.5);
      
      MealItem item = MealItem(food: fatFood, quantity: quantity);
      items.add(item);
      
      Map<String, double> macros = item.calculateMacros();
      currentProtein += macros['protein'] ?? 0;
      currentCarbs += macros['carbs'] ?? 0;
      currentFats += macros['fats'] ?? 0;
      currentCalories += macros['calories'] ?? 0;
    }
    
    // Add vegetables for micronutrients
    if (veggieFoods.isNotEmpty) {
      Food veggieFood = veggieFoods[DateTime.now().minute % veggieFoods.length];
      MealItem item = MealItem(food: veggieFood, quantity: veggieFood.servingSize);
      items.add(item);
      
      Map<String, double> macros = item.calculateMacros();
      currentProtein += macros['protein'] ?? 0;
      currentCarbs += macros['carbs'] ?? 0;
      currentFats += macros['fats'] ?? 0;
      currentCalories += macros['calories'] ?? 0;
    }
    
    return Meal(name: name, items: items);
  }
} 