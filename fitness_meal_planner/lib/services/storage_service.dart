import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../models/meal.dart';
import '../models/food.dart';

class StorageService {
  static const String _userKey = 'user_data';
  static const String _lastMealPlanKey = 'last_meal_plan';
  
  // Save user data to local storage
  Future<bool> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }
  
  // Load user data from local storage
  Future<User?> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userData = prefs.getString(_userKey);
      
      if (userData != null) {
        Map<String, dynamic> userMap = jsonDecode(userData);
        return User.fromJson(userMap);
      }
      return null;
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }
  
  // Save the last meal plan to local storage
  Future<bool> saveLastMealPlan(MealPlan mealPlan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_lastMealPlanKey, jsonEncode(mealPlan.toJson()));
    } catch (e) {
      print('Error saving meal plan: $e');
      return false;
    }
  }
  
  // Load the last meal plan from local storage
  Future<MealPlan?> loadLastMealPlan(List<Food> foodDatabase) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? mealPlanData = prefs.getString(_lastMealPlanKey);
      
      if (mealPlanData != null) {
        Map<String, dynamic> mealPlanMap = jsonDecode(mealPlanData);
        return MealPlan.fromJson(mealPlanMap, foodDatabase);
      }
      return null;
    } catch (e) {
      print('Error loading meal plan: $e');
      return null;
    }
  }
  
  // Clear all stored data (for logout/reset)
  Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
} 