import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/scanned_food.dart';
import '../services/food_scan_service.dart';

class FoodScanProvider with ChangeNotifier {
  final FoodScanService _foodScanService = FoodScanService();
  
  List<ScannedFood> _scannedFoodHistory = [];
  ScannedFood? _currentScannedFood;
  bool _isScanning = false;
  File? _currentImage;
  String? _errorMessage;

  List<ScannedFood> get scannedFoodHistory => _scannedFoodHistory;
  ScannedFood? get currentScannedFood => _currentScannedFood;
  bool get isScanning => _isScanning;
  File? get currentImage => _currentImage;
  String? get errorMessage => _errorMessage;

  Future<void> pickImageAndScan(ImageSource source) async {
    try {
      _errorMessage = null;
      _isScanning = true;
      notifyListeners();

      final File? pickedImage = await _foodScanService.pickImage(source);
      
      if (pickedImage == null) {
        _isScanning = false;
        notifyListeners();
        return;
      }
      
      _currentImage = pickedImage;
      notifyListeners();
      
      final ScannedFood? recognizedFood = await _foodScanService.recognizeFood(pickedImage);
      
      if (recognizedFood != null) {
        _currentScannedFood = recognizedFood;
        _scannedFoodHistory.insert(0, recognizedFood);
        if (_scannedFoodHistory.length > 20) {
          _scannedFoodHistory.removeLast();
        }
      } else {
        _errorMessage = 'Could not recognize the food in this image. Please try again.';
      }
      
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _isScanning = false;
      _errorMessage = 'An error occurred while scanning: $e';
      notifyListeners();
    }
  }
  
  Future<void> scanBarcode(String barcode) async {
    try {
      _errorMessage = null;
      _isScanning = true;
      notifyListeners();
      
      final ScannedFood? scannedFood = await _foodScanService.scanBarcode(barcode);
      
      if (scannedFood != null) {
        _currentScannedFood = scannedFood;
        _scannedFoodHistory.insert(0, scannedFood);
        if (_scannedFoodHistory.length > 20) {
          _scannedFoodHistory.removeLast();
        }
      } else {
        _errorMessage = 'Could not find a food product with this barcode. Please try again.';
      }
      
      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _isScanning = false;
      _errorMessage = 'An error occurred while scanning the barcode: $e';
      notifyListeners();
    }
  }
  
  void clearCurrentScan() {
    _currentScannedFood = null;
    _currentImage = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  void removeFromHistory(ScannedFood food) {
    _scannedFoodHistory.remove(food);
    notifyListeners();
  }
  
  void clearHistory() {
    _scannedFoodHistory.clear();
    notifyListeners();
  }
  
  // Method to set the current scanned food manually
  void setCurrentScannedFood(ScannedFood food) {
    _currentScannedFood = food;
    notifyListeners();
  }
} 