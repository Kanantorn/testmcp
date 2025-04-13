import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/food.dart';

class FoodService {
  List<Food> _foods = [];
  bool _isLoaded = false;

  Future<List<Food>> getFoods() async {
    if (!_isLoaded) {
      await _loadFoods();
    }
    return _foods;
  }

  Future<void> _loadFoods() async {
    try {
      // Load the JSON file from assets
      final String response = await rootBundle.loadString('assets/food_database.json');
      final List<dynamic> data = json.decode(response);
      
      // Convert each item to a Food object
      _foods = data.map((item) => Food.fromJson(item)).toList();
      _isLoaded = true;
    } catch (e) {
      print('Error loading food database: $e');
      // Provide some fallback data if loading fails
      _foods = _getFallbackFoods();
      _isLoaded = true;
    }
  }

  // Search for foods by name
  Future<List<Food>> searchFoods(String query) async {
    if (!_isLoaded) {
      await _loadFoods();
    }
    
    query = query.toLowerCase();
    return _foods.where((food) => 
      food.name.toLowerCase().contains(query) ||
      food.category.toLowerCase().contains(query)
    ).toList();
  }

  // Get foods by category
  Future<List<Food>> getFoodsByCategory(String category) async {
    if (!_isLoaded) {
      await _loadFoods();
    }
    
    return _foods.where((food) => food.category.toLowerCase() == category.toLowerCase()).toList();
  }

  // Fallback foods in case the database fails to load
  List<Food> _getFallbackFoods() {
    return [
      Food(
        id: 1,
        name: 'Chicken Breast',
        calories: 165,
        protein: 31,
        carbs: 0,
        fats: 3.6,
        servingSize: 100,
        servingUnit: 'g',
        category: 'protein',
      ),
      Food(
        id: 5,
        name: 'Oatmeal',
        calories: 389,
        protein: 16.9,
        carbs: 66.3,
        fats: 6.9,
        servingSize: 100,
        servingUnit: 'g',
        category: 'carbs',
      ),
      Food(
        id: 9,
        name: 'Avocado',
        calories: 160,
        protein: 2,
        carbs: 8.5,
        fats: 14.7,
        servingSize: 100,
        servingUnit: 'g',
        category: 'fats',
      ),
      Food(
        id: 12,
        name: 'Broccoli',
        calories: 34,
        protein: 2.8,
        carbs: 6.6,
        fats: 0.4,
        servingSize: 100,
        servingUnit: 'g',
        category: 'vegetables',
      ),
    ];
  }
} 