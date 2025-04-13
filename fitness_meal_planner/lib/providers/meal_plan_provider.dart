import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../models/user.dart';
import '../services/mcp_service.dart';
import '../services/food_service.dart';
import '../services/storage_service.dart';

class MealPlanProvider extends ChangeNotifier {
  MealPlan? _mealPlan;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  final FoodService _foodService = FoodService();
  final StorageService _storageService = StorageService();
  late final MCPService _mcpService;
  
  MealPlanProvider() {
    _mcpService = MCPService(foodService: _foodService);
  }
  
  MealPlan? get mealPlan => _mealPlan;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  
  // Load the last saved meal plan
  Future<void> loadLastMealPlan() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final foods = await _foodService.getFoods();
      _mealPlan = await _storageService.loadLastMealPlan(foods);
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to load saved meal plan';
      print('Error loading meal plan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Generate a new meal plan using MCP
  Future<void> generateMealPlan(User user) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Try to use MCP first
      try {
        _mealPlan = await _mcpService.generateMealPlan(user);
      } catch (mcpError) {
        print('MCP error, falling back to default plan: $mcpError');
        // Fall back to basic plan generation if MCP fails
        _mealPlan = await _mcpService.generateFallbackMealPlan(user);
      }
      
      // Save the generated plan
      if (_mealPlan != null) {
        await _storageService.saveLastMealPlan(_mealPlan!);
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Failed to generate meal plan';
      print('Error generating meal plan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get total macros for the current meal plan
  Map<String, double> getMealPlanMacros() {
    if (_mealPlan == null) {
      return {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fats': 0,
      };
    }
    
    return _mealPlan!.calculateTotalMacros();
  }
  
  // Clear the current meal plan
  void clearMealPlan() {
    _mealPlan = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
} 