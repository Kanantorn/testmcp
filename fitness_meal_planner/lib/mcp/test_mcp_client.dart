import 'dart:convert';
import 'dart:io';

import '../models/user.dart';
import '../models/food.dart';
import 'sequential_thinking_task.dart';
import 'sequential_thinking_runner.dart';

/// A simple test client for the MCP Sequential Thinking server
/// This can be run from the command line to test the MCP server
Future<void> main() async {
  print('MCP Sequential Thinking Test Client');
  print('-----------------------------------');
  
  // Create a test user
  final user = User(
    id: 'test-user',
    name: 'Test User',
    age: 30,
    weight: 75.0,
    height: 175.0,
    gender: 'Male',
    activityLevel: 'Moderately Active',
    goal: 'Muscle Gain',
  );
  
  // Get target macros
  final targetMacros = user.calculateMacros();
  print('Target Macros:');
  print('Calories: ${targetMacros['calories']?.toStringAsFixed(0)} kcal');
  print('Protein: ${targetMacros['protein']?.toStringAsFixed(0)} g');
  print('Carbs: ${targetMacros['carbs']?.toStringAsFixed(0)} g');
  print('Fats: ${targetMacros['fats']?.toStringAsFixed(0)} g');
  print('');
  
  // Load sample foods
  final sampleFoods = _loadSampleFoods();
  print('Loaded ${sampleFoods.length} sample foods');
  print('');
  
  // Convert food objects to JSON
  final foodsJson = sampleFoods.map((f) => f.toJson()).toList();
  
  // Prepare input data
  final inputData = {
    'user_profile': user.toJson(),
    'target_macros': targetMacros,
    'available_foods': foodsJson,
  };
  
  print('Sending request to MCP Server...');
  try {
    // Call MCP Sequential Thinking
    final result = await MCPSequentialThinkingRunner.generateMealPlan(
      userProfile: user.toJson(),
      targetMacros: targetMacros,
      availableFoods: foodsJson,
    );
    
    print('Received response from MCP Server');
    print('Status: ${result['status']}');
    print('Message: ${result['message']}');
    print('');
    
    // Print the meal plan
    if (result.containsKey('meal_plan')) {
      final mealPlan = result['meal_plan'];
      
      // Format the meal plan for display
      print('MEAL PLAN:');
      print('==========');
      
      if (mealPlan['meals'] != null) {
        for (var meal in mealPlan['meals']) {
          print('${meal['name']}:');
          
          if (meal['items'] != null) {
            for (var item in meal['items']) {
              // Find the food in our sample foods
              final foodId = item['food_id'];
              final food = sampleFoods.firstWhere(
                (f) => f.id == foodId, 
                orElse: () => Food(
                  id: 0, 
                  name: 'Unknown', 
                  calories: 0, 
                  protein: 0, 
                  carbs: 0, 
                  fats: 0, 
                  servingSize: 0, 
                  servingUnit: 'g', 
                  category: 'unknown'
                )
              );
              
              print('  - ${food.name}: ${item['quantity'].toStringAsFixed(1)} ${food.servingUnit}');
            }
          }
          
          // Print meal macros if available
          if (meal['macros'] != null) {
            print('  Macros: ${meal['macros']['calories'].toStringAsFixed(0)} kcal, ' +
                  'P: ${meal['macros']['protein'].toStringAsFixed(1)}g, ' +
                  'C: ${meal['macros']['carbs'].toStringAsFixed(1)}g, ' +
                  'F: ${meal['macros']['fats'].toStringAsFixed(1)}g');
          }
          
          print('');
        }
      }
      
      // Print total macros
      if (mealPlan['total_macros'] != null) {
        print('Total Macros:');
        print('Calories: ${mealPlan['total_macros']['calories'].toStringAsFixed(0)} kcal');
        print('Protein: ${mealPlan['total_macros']['protein'].toStringAsFixed(1)} g');
        print('Carbs: ${mealPlan['total_macros']['carbs'].toStringAsFixed(1)} g');
        print('Fats: ${mealPlan['total_macros']['fats'].toStringAsFixed(1)} g');
      }
    } else {
      print('No meal plan data found in the response');
      print('Raw response:');
      print(json.encode(result));
    }
  } catch (e) {
    print('Error calling MCP Server: $e');
  }
}

// Load a set of sample foods for testing
List<Food> _loadSampleFoods() {
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
      id: 2,
      name: 'Salmon',
      calories: 208,
      protein: 20,
      carbs: 0,
      fats: 13,
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
      id: 6,
      name: 'Brown Rice',
      calories: 112,
      protein: 2.6,
      carbs: 23.5,
      fats: 0.9,
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
      id: 10,
      name: 'Olive Oil',
      calories: 884,
      protein: 0,
      carbs: 0,
      fats: 100,
      servingSize: 100,
      servingUnit: 'ml',
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
    Food(
      id: 13,
      name: 'Spinach',
      calories: 23,
      protein: 2.9,
      carbs: 3.6,
      fats: 0.4,
      servingSize: 100,
      servingUnit: 'g',
      category: 'vegetables',
    ),
  ];
} 