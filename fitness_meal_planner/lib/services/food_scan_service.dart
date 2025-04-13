import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/scanned_food.dart';

class FoodScanService {
  // USDA FoodData Central API
  static const String apiBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  // Get your API key from https://fdc.nal.usda.gov/api-key-signup.html
  static const String apiKey = 'WNkJlvLyIZm9yoRUT3nArGyzQ40SdXGd8yBER1vG'; // Replace with your actual API key
  
  // Common food keywords to simulate image recognition
  static const List<String> commonFoods = [
    'apple', 'banana', 'chicken breast', 'rice', 'broccoli', 
    'avocado', 'salmon', 'sweet potato', 'yogurt', 'quinoa',
    'beef', 'egg', 'milk', 'spinach', 'carrot'
  ];

  // Fallback mock data in case API calls fail
  final Map<String, ScannedFood> _mockFoodDatabase = {
    'apple': ScannedFood(
      name: 'Apple',
      imageUrl: 'https://example.com/images/apple.jpg',
      calories: 52,
      protein: 0.3,
      carbs: 14,
      fat: 0.2,
      fiber: 2.4,
      sugar: 10.3,
      scanTime: DateTime.now(),
    ),
    'banana': ScannedFood(
      name: 'Banana',
      imageUrl: 'https://example.com/images/banana.jpg',
      calories: 89,
      protein: 1.1,
      carbs: 22.8,
      fat: 0.3,
      fiber: 2.6,
      sugar: 12.2,
      scanTime: DateTime.now(),
    ),
    'chicken breast': ScannedFood(
      name: 'Chicken Breast',
      imageUrl: 'https://example.com/images/chicken_breast.jpg',
      calories: 165,
      protein: 31,
      carbs: 0,
      fat: 3.6,
      scanTime: DateTime.now(),
    ),
    'rice': ScannedFood(
      name: 'White Rice (Cooked)',
      imageUrl: 'https://example.com/images/rice.jpg',
      calories: 130,
      protein: 2.7,
      carbs: 28.2,
      fat: 0.3,
      fiber: 0.4,
      scanTime: DateTime.now(),
    ),
    'broccoli': ScannedFood(
      name: 'Broccoli',
      imageUrl: 'https://example.com/images/broccoli.jpg',
      calories: 34,
      protein: 2.8,
      carbs: 6.6,
      fat: 0.4,
      fiber: 2.6,
      sugar: 1.7,
      scanTime: DateTime.now(),
    ),
  };

  // Barcode database - these would normally come from a real API
  final Map<String, String> _barcodeToFdcId = {
    '123456789': '167771', // Barcode for Apple (sample)
    '234567890': '173430', // Barcode for Chicken breast (sample)
    '345678901': '168191', // Barcode for Yogurt (sample)
    '456789012': '168882', // Barcode for White rice (sample)
    '567890123': '747447', // Barcode for Avocado (sample)
  };

  Future<File?> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<ScannedFood?> recognizeFood(File imageFile) async {
    // In a real app, this would send the image to a food recognition API
    // For now, we'll simulate image recognition by randomly picking a food
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Simulate food recognition by picking a random food
      final random = Random();
      final foodName = commonFoods[random.nextInt(commonFoods.length)];
      
      // Try to get real nutrition data from USDA FoodData Central API
      try {
        return await _getFoodDataFromApi(foodName);
      } catch (e) {
        print('Error fetching from API, falling back to mock data: $e');
        // Fallback to mock data if API call fails
        return _mockFoodDatabase[foodName.toLowerCase()] ?? _generateRandomFood(foodName);
      }
    } catch (e) {
      print('Error recognizing food: $e');
      return null;
    }
  }

  Future<ScannedFood?> scanBarcode(String barcode) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Check if we have an FDC ID for this barcode
      final fdcId = _barcodeToFdcId[barcode];
      
      if (fdcId != null) {
        // Get food data from the USDA API using the FDC ID
        try {
          return await _getFoodDetailsById(fdcId, barcode);
        } catch (e) {
          print('Error fetching barcode food from API: $e');
          // Fallback to mock data
          return _generateRandomPackagedFood(barcode);
        }
      } else {
        // Generate a random packaged food for unknown barcodes
        return _generateRandomPackagedFood(barcode);
      }
    } catch (e) {
      print('Error scanning barcode: $e');
      return null;
    }
  }

  // Get food data from USDA FoodData Central API by search term
  Future<ScannedFood> _getFoodDataFromApi(String foodName) async {
    // Construct the search URL
    final uri = Uri.parse('$apiBaseUrl/foods/search?api_key=$apiKey&query=$foodName&pageSize=1');
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      if (data['foods'] != null && data['foods'].isNotEmpty) {
        final food = data['foods'][0];
        
        // Extract nutrient values
        double calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0, sugar = 0;
        
        // Parse nutrients
        if (food['foodNutrients'] != null) {
          for (var nutrient in food['foodNutrients']) {
            switch (nutrient['nutrientId']) {
              case 1008: // Energy (kcal)
                calories = (nutrient['value'] ?? 0).toDouble();
                break;
              case 1003: // Protein
                protein = (nutrient['value'] ?? 0).toDouble();
                break;
              case 1005: // Carbohydrates
                carbs = (nutrient['value'] ?? 0).toDouble();
                break;
              case 1004: // Total fat
                fat = (nutrient['value'] ?? 0).toDouble();
                break;
              case 1079: // Fiber
                fiber = (nutrient['value'] ?? 0).toDouble();
                break;
              case 2000: // Total sugars
                sugar = (nutrient['value'] ?? 0).toDouble();
                break;
            }
          }
        }
        
        return ScannedFood(
          name: food['description'] ?? foodName,
          imageUrl: 'https://spoonacular.com/cdn/ingredients_250x250/${foodName.toLowerCase().replaceAll(' ', '-')}.jpg',
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          fiber: fiber,
          sugar: sugar,
          scanTime: DateTime.now(),
        );
      }
    }
    
    // If the API call fails or returns no results, throw an exception
    throw Exception('Food not found in USDA database');
  }

  // Get food details from USDA FoodData Central API by FDC ID
  Future<ScannedFood> _getFoodDetailsById(String fdcId, String barcode) async {
    // Construct the URL
    final uri = Uri.parse('$apiBaseUrl/food/$fdcId?api_key=$apiKey');
    
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> food = json.decode(response.body);
      
      // Extract nutrient values
      double calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0, sugar = 0;
      
      // Parse nutrients
      if (food['foodNutrients'] != null) {
        for (var nutrient in food['foodNutrients']) {
          final nutrientId = nutrient['nutrient']?['id'] ?? 0;
          final value = nutrient['amount'] ?? 0;
          
          switch (nutrientId) {
            case 1008: // Energy (kcal)
              calories = value.toDouble();
              break;
            case 1003: // Protein
              protein = value.toDouble();
              break;
            case 1005: // Carbohydrates
              carbs = value.toDouble();
              break;
            case 1004: // Total fat
              fat = value.toDouble();
              break;
            case 1079: // Fiber
              fiber = value.toDouble();
              break;
            case 2000: // Total sugars
              sugar = value.toDouble();
              break;
          }
        }
      }
      
      return ScannedFood(
        name: food['description'] ?? 'Packaged Food',
        imageUrl: 'https://spoonacular.com/cdn/ingredients_100x100/${food['description'].toString().toLowerCase().replaceAll(' ', '-')}.jpg',
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        sugar: sugar,
        barcode: barcode,
        scanTime: DateTime.now(),
      );
    }
    
    // If the API call fails, throw an exception
    throw Exception('Food not found in USDA database');
  }

  // Generate a random food for fallback
  ScannedFood _generateRandomFood(String name) {
    final random = Random();
    
    return ScannedFood(
      name: name.substring(0, 1).toUpperCase() + name.substring(1),
      imageUrl: 'https://spoonacular.com/cdn/ingredients_250x250/${name.toLowerCase().replaceAll(' ', '-')}.jpg',
      calories: 50 + random.nextInt(200).toDouble(),
      protein: 1 + random.nextInt(30).toDouble(),
      carbs: 5 + random.nextInt(40).toDouble(),
      fat: 1 + random.nextInt(15).toDouble(),
      fiber: random.nextInt(10).toDouble(),
      sugar: random.nextInt(20).toDouble(),
      scanTime: DateTime.now(),
    );
  }
  
  // Generate a random packaged food for fallback
  ScannedFood _generateRandomPackagedFood(String barcode) {
    final random = Random();
    final foodTypes = ['Energy Bar', 'Cereal', 'Yogurt', 'Chips', 'Juice', 'Snack', 'Frozen Meal', 'Drink'];
    final brands = ['Nature\'s Best', 'Healthy Choice', 'Organic Valley', 'Fitness Pro', 'Whole Foods', 'Protein Plus'];
    
    final foodType = foodTypes[random.nextInt(foodTypes.length)];
    final brand = brands[random.nextInt(brands.length)];
    final name = '$brand $foodType';
    
    return ScannedFood(
      name: name,
      calories: 150 + random.nextInt(250).toDouble(),
      protein: 2 + random.nextInt(25).toDouble(),
      carbs: 15 + random.nextInt(35).toDouble(),
      fat: 2 + random.nextInt(20).toDouble(),
      fiber: random.nextInt(8).toDouble(),
      sugar: 5 + random.nextInt(25).toDouble(),
      barcode: barcode,
      scanTime: DateTime.now(),
    );
  }
} 