class MCPSequentialThinkingTask {
  static const String mealPlanningTask = '''
Generate a balanced meal plan based on the user's profile and target macros.

Follow these steps:
1. Calculate meal distribution (breakfast 25%, lunch 35%, dinner 30%, snack 10%)
2. Categorize available foods (protein, carbs, fats, vegetables)
3. For each meal:
   a. Calculate target macros based on distribution
   b. Adjust targets based on user goal (weight loss, muscle gain, maintenance)
   c. Select protein source and calculate quantity
   d. Select carb source and calculate quantity
   e. Select fat source and calculate quantity
   f. Add vegetables for micronutrients
   g. Calculate total macros for the meal
4. Compile the complete meal plan
5. Calculate total daily macros and compare with targets
6. Make final adjustments if needed

Return a complete meal plan with specific foods and quantities for each meal,
along with the nutritional breakdown.
''';

  static String buildPrompt(Map<String, dynamic> inputData) {
    final userProfile = inputData['user_profile'];
    final targetMacros = inputData['target_macros'];
    final availableFoods = inputData['available_foods'];
    
    return '''
Task: $mealPlanningTask

User Profile:
${_formatUserProfile(userProfile)}

Target Macros:
${_formatTargetMacros(targetMacros)}

Available Foods:
${_formatAvailableFoods(availableFoods)}

Please return a JSON object with the following structure:
{
  "meal_plan": {
    "meals": [
      {
        "name": "Breakfast",
        "items": [
          { "food_id": "1", "quantity": 100 }
        ],
        "macros": {
          "calories": 500,
          "protein": 30,
          "carbs": 50,
          "fats": 15
        }
      }
    ],
    "total_macros": {
      "calories": 2000,
      "protein": 150,
      "carbs": 200,
      "fats": 65
    }
  }
}
''';
  }

  static String _formatUserProfile(Map<String, dynamic> userProfile) {
    return '''
- Name: ${userProfile['name'] ?? 'Unknown'}
- Age: ${userProfile['age'] ?? 'Unknown'} years
- Gender: ${userProfile['gender'] ?? 'Unknown'}
- Weight: ${userProfile['weight'] ?? 'Unknown'} kg
- Height: ${userProfile['height'] ?? 'Unknown'} cm
- Activity Level: ${userProfile['activityLevel'] ?? 'Unknown'}
- Goal: ${userProfile['goal'] ?? 'Unknown'}
''';
  }

  static String _formatTargetMacros(Map<String, dynamic> targetMacros) {
    return '''
- Calories: ${targetMacros['calories']?.toStringAsFixed(0) ?? 'Unknown'} kcal
- Protein: ${targetMacros['protein']?.toStringAsFixed(0) ?? 'Unknown'} g
- Carbs: ${targetMacros['carbs']?.toStringAsFixed(0) ?? 'Unknown'} g
- Fats: ${targetMacros['fats']?.toStringAsFixed(0) ?? 'Unknown'} g
''';
  }

  static String _formatAvailableFoods(List<dynamic> availableFoods) {
    StringBuffer buffer = StringBuffer();
    
    for (var food in availableFoods) {
      buffer.writeln('''
- ID: ${food['id']}
  Name: ${food['name']}
  Category: ${food['category']}
  Serving Size: ${food['serving_size']} g
  Calories: ${food['calories']} kcal
  Protein: ${food['protein']} g
  Carbs: ${food['carbs']} g
  Fats: ${food['fats']} g
''');
    }
    
    return buffer.toString();
  }
} 