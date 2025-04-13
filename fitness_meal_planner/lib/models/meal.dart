import 'food.dart';

class MealItem {
  final Food food;
  final double quantity;

  MealItem({
    required this.food,
    required this.quantity,
  });

  factory MealItem.fromJson(Map<String, dynamic> json, List<Food> foodDatabase) {
    // Find the food in the database by id
    Food foodItem = foodDatabase.firstWhere((food) => food.id == json['foodId']);
    
    return MealItem(
      food: foodItem,
      quantity: json['quantity'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': food.id,
      'quantity': quantity,
    };
  }

  // Calculate macros for this meal item based on quantity
  Map<String, double> calculateMacros() {
    return food.calculateMacrosForPortion(quantity);
  }
}

class Meal {
  final String name;
  final List<MealItem> items;

  Meal({
    required this.name,
    required this.items,
  });

  factory Meal.fromJson(Map<String, dynamic> json, List<Food> foodDatabase) {
    return Meal(
      name: json['name'],
      items: (json['items'] as List)
          .map((item) => MealItem.fromJson(item, foodDatabase))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Calculate total macros for this meal
  Map<String, double> calculateTotalMacros() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (var item in items) {
      Map<String, double> macros = item.calculateMacros();
      totalCalories += macros['calories'] ?? 0;
      totalProtein += macros['protein'] ?? 0;
      totalCarbs += macros['carbs'] ?? 0;
      totalFats += macros['fats'] ?? 0;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fats': totalFats,
    };
  }
}

class MealPlan {
  final String id;
  final DateTime date;
  final List<Meal> meals;

  MealPlan({
    required this.id,
    required this.date,
    required this.meals,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json, List<Food> foodDatabase) {
    return MealPlan(
      id: json['id'],
      date: DateTime.parse(json['date']),
      meals: (json['meals'] as List)
          .map((meal) => Meal.fromJson(meal, foodDatabase))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'meals': meals.map((meal) => meal.toJson()).toList(),
    };
  }

  // Calculate total macros for the entire meal plan
  Map<String, double> calculateTotalMacros() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    for (var meal in meals) {
      Map<String, double> macros = meal.calculateTotalMacros();
      totalCalories += macros['calories'] ?? 0;
      totalProtein += macros['protein'] ?? 0;
      totalCarbs += macros['carbs'] ?? 0;
      totalFats += macros['fats'] ?? 0;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fats': totalFats,
    };
  }
} 