import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/food.dart';
import '../models/meal.dart';
import '../services/food_service.dart';

class FoodLogEntry {
  final String id;
  final DateTime date;
  final Food food;
  final double quantity;
  final String mealType; // Breakfast, Lunch, Dinner, Snack

  FoodLogEntry({
    required this.id,
    required this.date,
    required this.food,
    required this.quantity,
    required this.mealType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'foodId': food.id,
      'quantity': quantity,
      'mealType': mealType,
    };
  }

  static FoodLogEntry fromJson(Map<String, dynamic> json, List<Food> foodDatabase) {
    Food foodItem = foodDatabase.firstWhere((f) => f.id == json['foodId']);
    
    return FoodLogEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      food: foodItem,
      quantity: json['quantity'].toDouble(),
      mealType: json['mealType'],
    );
  }

  // Calculate macros for this log entry
  Map<String, double> calculateMacros() {
    return food.calculateMacrosForPortion(quantity);
  }
}

class FoodLogProvider extends ChangeNotifier {
  List<FoodLogEntry> _logEntries = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  final FoodService _foodService = FoodService();
  
  List<FoodLogEntry> get logEntries => _logEntries;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  
  // Filter entries by selected date
  List<FoodLogEntry> get entriesForSelectedDate {
    return _logEntries.where((entry) => 
      entry.date.year == _selectedDate.year &&
      entry.date.month == _selectedDate.month &&
      entry.date.day == _selectedDate.day
    ).toList();
  }
  
  // Group entries by meal type for the selected date
  Map<String, List<FoodLogEntry>> get entriesByMealType {
    final Map<String, List<FoodLogEntry>> result = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snack': [],
    };
    
    for (var entry in entriesForSelectedDate) {
      result[entry.mealType]?.add(entry);
    }
    
    return result;
  }
  
  // Set the selected date
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }
  
  // Load log entries from storage
  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString('food_log') ?? '[]';
      final List<dynamic> entriesData = json.decode(entriesJson);
      final foods = await _foodService.getFoods();
      
      _logEntries = entriesData
          .map((entry) => FoodLogEntry.fromJson(entry, foods))
          .toList();
    } catch (e) {
      print('Error loading food log: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Save current entries to storage
  Future<void> _saveEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = json.encode(_logEntries.map((e) => e.toJson()).toList());
      await prefs.setString('food_log', entriesJson);
    } catch (e) {
      print('Error saving food log: $e');
    }
  }
  
  // Add a new entry
  Future<void> addEntry(Food food, double quantity, String mealType) async {
    final entry = FoodLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      food: food,
      quantity: quantity,
      mealType: mealType,
    );
    
    _logEntries.add(entry);
    await _saveEntries();
    notifyListeners();
  }
  
  // Add multiple entries (e.g., from a meal plan)
  Future<void> addEntriesFromMeal(Meal meal, String mealType) async {
    for (var item in meal.items) {
      await addEntry(item.food, item.quantity, mealType);
    }
  }
  
  // Remove an entry
  Future<void> removeEntry(String id) async {
    _logEntries.removeWhere((entry) => entry.id == id);
    await _saveEntries();
    notifyListeners();
  }
  
  // Clear all entries for the selected date
  Future<void> clearEntriesForSelectedDate() async {
    _logEntries.removeWhere((entry) => 
      entry.date.year == _selectedDate.year &&
      entry.date.month == _selectedDate.month &&
      entry.date.day == _selectedDate.day
    );
    await _saveEntries();
    notifyListeners();
  }
  
  // Calculate total macros for the selected date
  Map<String, double> getTotalMacrosForSelectedDate() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFats = 0;
    
    for (var entry in entriesForSelectedDate) {
      Map<String, double> macros = entry.calculateMacros();
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