import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  final StorageService _storageService = StorageService();
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUserSet => _user != null;
  
  // Load user data from storage on app start
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _user = await _storageService.loadUser();
    } catch (e) {
      print('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Save and update user data
  Future<bool> saveUser(User user) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      bool result = await _storageService.saveUser(user);
      if (result) {
        _user = user;
      }
      return result;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update specific user fields
  Future<bool> updateUser({
    String? name,
    int? age,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
    String? goal,
  }) async {
    if (_user == null) return false;
    
    User updatedUser = User(
      id: _user!.id,
      name: name ?? _user!.name,
      age: age ?? _user!.age,
      weight: weight ?? _user!.weight,
      height: height ?? _user!.height,
      gender: gender ?? _user!.gender,
      activityLevel: activityLevel ?? _user!.activityLevel,
      goal: goal ?? _user!.goal,
    );
    
    return await saveUser(updatedUser);
  }
  
  // Get the user's calculated macros
  Map<String, double> getUserMacros() {
    if (_user == null) {
      return {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fats': 0,
      };
    }
    
    return _user!.calculateMacros();
  }
  
  // Clear user data (logout)
  Future<bool> clearUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      bool result = await _storageService.clearAllData();
      if (result) {
        _user = null;
      }
      return result;
    } catch (e) {
      print('Error clearing user data: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 