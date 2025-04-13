import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/food.dart';
import '../models/meal.dart';
import 'sequential_thinking_task.dart';

class MCPSequentialThinkingRunner {
  static Future<Map<String, dynamic>> runSequentialThinking({
    required String task,
    required Map<String, dynamic> inputData,
    int maxThoughts = 10,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      // Connect to the already running MCP Sequential Thinking server
      // This assumes the server is already running in the terminal
      final process = await Process.start('npx', ['@modelcontextprotocol/client'], 
          mode: ProcessStartMode.normal);
      
      // Create completer for the result
      Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();
      
      // Buffer for storing output
      StringBuffer outputBuffer = StringBuffer();
      
      // Request to send to the MCP server
      Map<String, dynamic> request = {
        'method': 'sequential_thinking',
        'params': {
          'task': task,
          'input_data': inputData,
          'max_thoughts': maxThoughts,
        }
      };
      
      // Send the request to the MCP client
      process.stdin.writeln(json.encode(request));
      
      // Listen for responses from the MCP client
      process.stdout.transform(utf8.decoder).listen((data) {
        print('MCP Response: $data');
        outputBuffer.write(data);
        
        try {
          // Try to parse the current buffer as JSON
          // Each line should be a separate JSON object
          String bufferedOutput = outputBuffer.toString();
          List<String> lines = bufferedOutput.split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList();
          
          for (String line in lines) {
            try {
              Map<String, dynamic> parsed = json.decode(line);
              
              // Check if this is the final result
              if (parsed.containsKey('result') && !completer.isCompleted) {
                completer.complete(parsed['result']);
                process.kill();
                break;
              }
              
              // Check for errors
              if (parsed.containsKey('error') && !completer.isCompleted) {
                completer.completeError(parsed['error']);
                process.kill();
                break;
              }
            } catch (e) {
              // JSON parsing failed for this line, continue with next line
              continue;
            }
          }
        } catch (e) {
          // JSON parsing failed, keep accumulating output
        }
      });
      
      // Handle errors from the MCP client
      process.stderr.transform(utf8.decoder).listen((data) {
        print('MCP Sequential Thinking Client Error: $data');
      });
      
      // Handle process exit
      process.exitCode.then((exitCode) {
        if (!completer.isCompleted) {
          if (exitCode != 0) {
            completer.completeError('MCP client process exited with code $exitCode');
          }
        }
      });
      
      // Add timeout
      Timer(timeout, () {
        if (!completer.isCompleted) {
          process.kill();
          completer.completeError('MCP process timed out after $timeout');
        }
      });
      
      // Wait for completion or timeout
      return completer.future;
    } catch (e) {
      throw Exception('Failed to run Sequential Thinking: $e');
    }
  }
  
  /// Generate a meal plan using the MCP Sequential Thinking API
  static Future<Map<String, dynamic>> generateMealPlan({
    required Map<String, dynamic> userProfile,
    required Map<String, double> targetMacros,
    required List<Map<String, dynamic>> availableFoods,
  }) async {
    // Prepare input data for the MCP request
    Map<String, dynamic> inputData = {
      'user_profile': userProfile,
      'target_macros': targetMacros,
      'available_foods': availableFoods,
    };

    // Build the prompt using our task class
    String prompt = MCPSequentialThinkingTask.buildPrompt(inputData);
    
    try {
      // Connect to the already running MCP server
      final result = await runSequentialThinking(
        task: MCPSequentialThinkingTask.mealPlanningTask,
        inputData: inputData,
        maxThoughts: 8,
        timeout: const Duration(seconds: 120),
      );
      
      // Extract and return the meal plan
      if (result.containsKey('meal_plan')) {
        return {
          'meal_plan': result['meal_plan'],
          'status': 'success',
          'message': 'Meal plan generated successfully via MCP',
        };
      }
      
      // If we didn't get the expected format, transform it
      if (result is Map<String, dynamic>) {
        try {
          // Try to parse any JSON string that might be in the result
          if (result.containsKey('answer') && result['answer'] is String) {
            try {
              final jsonStr = result['answer'] as String;
              final parsedJson = json.decode(jsonStr);
              if (parsedJson is Map<String, dynamic> && parsedJson.containsKey('meal_plan')) {
                return {
                  'meal_plan': parsedJson['meal_plan'],
                  'status': 'success',
                  'message': 'Meal plan generated successfully via MCP',
                };
              }
            } catch (e) {
              print('Error parsing MCP response JSON: $e');
            }
          }
          
          // If we get here, just return the raw result and let the calling code handle it
          return {
            'meal_plan': result,
            'status': 'success', 
            'message': 'Raw MCP response returned',
          };
        } catch (e) {
          print('Error processing MCP response: $e');
          throw e;
        }
      }
      
      throw Exception('Unexpected MCP result format');
    } catch (e) {
      print('MCP error, falling back to default plan: $e');
      return _generateFallbackMealPlan(inputData);
    }
  }

  // Private method to generate a fallback meal plan
  static Future<Map<String, dynamic>> _generateFallbackMealPlan(Map<String, dynamic> inputData) async {
    // Extract target macros and available foods
    Map<String, double> targetMacros = 
        Map<String, double>.from(inputData['target_macros'] as Map);
    List<Map<String, dynamic>> availableFoodsMaps = 
        List<Map<String, dynamic>>.from(inputData['available_foods'] as List);
    
    // Convert food maps to Food objects
    List<Food> availableFoods = availableFoodsMaps
        .map((foodMap) => Food.fromJson(foodMap))
        .toList();

    // Create breakfast
    Map<String, dynamic> breakfast = _createSimpleMeal(
      'Breakfast', 
      availableFoods, 
      targetMacros, 
      0.25
    );

    // Create lunch
    Map<String, dynamic> lunch = _createSimpleMeal(
      'Lunch', 
      availableFoods, 
      targetMacros, 
      0.35
    );

    // Create dinner
    Map<String, dynamic> dinner = _createSimpleMeal(
      'Dinner', 
      availableFoods, 
      targetMacros, 
      0.30
    );

    // Create snack
    Map<String, dynamic> snack = _createSimpleMeal(
      'Snack', 
      availableFoods, 
      targetMacros, 
      0.10
    );

    // Calculate total macros
    double totalCalories = breakfast['macros']['calories'] + lunch['macros']['calories'] + 
                         dinner['macros']['calories'] + snack['macros']['calories'];
    double totalProtein = breakfast['macros']['protein'] + lunch['macros']['protein'] + 
                        dinner['macros']['protein'] + snack['macros']['protein'];
    double totalCarbs = breakfast['macros']['carbs'] + lunch['macros']['carbs'] + 
                      dinner['macros']['carbs'] + snack['macros']['carbs'];
    double totalFats = breakfast['macros']['fats'] + lunch['macros']['fats'] + 
                      dinner['macros']['fats'] + snack['macros']['fats'];

    // Compile the meal plan
    Map<String, dynamic> mealPlan = {
      'meals': [breakfast, lunch, dinner, snack],
      'total_macros': {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fats': totalFats,
      }
    };

    return {
      'meal_plan': mealPlan,
      'status': 'success',
      'message': 'Meal plan generated successfully (fallback)',
    };
  }

  // Private method to create a simple meal
  static Map<String, dynamic> _createSimpleMeal(
    String name, 
    List<Food> foods, 
    Map<String, double> targetMacros, 
    double mealRatio
  ) {
    // Calculate target macros for this meal
    double targetCalories = (targetMacros['calories'] ?? 2000) * mealRatio;
    double targetProtein = (targetMacros['protein'] ?? 150) * mealRatio;
    double targetCarbs = (targetMacros['carbs'] ?? 200) * mealRatio;
    double targetFats = (targetMacros['fats'] ?? 70) * mealRatio;
    
    List<Map<String, dynamic>> items = [];
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
      
      Map<String, dynamic> item = {
        'food_id': proteinFood.id,
        'quantity': quantity,
      };
      items.add(item);
      
      currentProtein += (proteinFood.protein * quantity) / proteinFood.servingSize;
      currentCarbs += (proteinFood.carbs * quantity) / proteinFood.servingSize;
      currentFats += (proteinFood.fats * quantity) / proteinFood.servingSize;
      currentCalories += (proteinFood.calories * quantity) / proteinFood.servingSize;
    }
    
    // Add carb source
    if (carbFoods.isNotEmpty) {
      Food carbFood = carbFoods[DateTime.now().microsecond % carbFoods.length];
      double quantity = (targetCarbs / carbFood.carbs) * carbFood.servingSize;
      quantity = quantity.clamp(carbFood.servingSize * 0.5, carbFood.servingSize * 2);
      
      Map<String, dynamic> item = {
        'food_id': carbFood.id,
        'quantity': quantity,
      };
      items.add(item);
      
      currentProtein += (carbFood.protein * quantity) / carbFood.servingSize;
      currentCarbs += (carbFood.carbs * quantity) / carbFood.servingSize;
      currentFats += (carbFood.fats * quantity) / carbFood.servingSize;
      currentCalories += (carbFood.calories * quantity) / carbFood.servingSize;
    }
    
    // Add fat source
    if (fatFoods.isNotEmpty) {
      Food fatFood = fatFoods[DateTime.now().second % fatFoods.length];
      double quantity = (targetFats / fatFood.fats) * fatFood.servingSize;
      quantity = quantity.clamp(fatFood.servingSize * 0.2, fatFood.servingSize * 1.5);
      
      Map<String, dynamic> item = {
        'food_id': fatFood.id,
        'quantity': quantity,
      };
      items.add(item);
      
      currentProtein += (fatFood.protein * quantity) / fatFood.servingSize;
      currentCarbs += (fatFood.carbs * quantity) / fatFood.servingSize;
      currentFats += (fatFood.fats * quantity) / fatFood.servingSize;
      currentCalories += (fatFood.calories * quantity) / fatFood.servingSize;
    }
    
    // Add vegetables for micronutrients
    if (veggieFoods.isNotEmpty) {
      Food veggieFood = veggieFoods[DateTime.now().minute % veggieFoods.length];
      double quantity = veggieFood.servingSize;
      
      Map<String, dynamic> item = {
        'food_id': veggieFood.id,
        'quantity': quantity,
      };
      items.add(item);
      
      currentProtein += (veggieFood.protein * quantity) / veggieFood.servingSize;
      currentCarbs += (veggieFood.carbs * quantity) / veggieFood.servingSize;
      currentFats += (veggieFood.fats * quantity) / veggieFood.servingSize;
      currentCalories += (veggieFood.calories * quantity) / veggieFood.servingSize;
    }
    
    return {
      'name': name,
      'items': items,
      'macros': {
        'calories': currentCalories,
        'protein': currentProtein,
        'carbs': currentCarbs,
        'fats': currentFats,
      }
    };
  }
} 