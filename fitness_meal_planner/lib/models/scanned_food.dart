class ScannedFood {
  final String name;
  final String? imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final String? barcode;
  final DateTime scanTime;
  final double servingSize;
  final String servingUnit;

  ScannedFood({
    required this.name,
    this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.barcode,
    required this.scanTime,
    this.servingSize = 100,
    this.servingUnit = 'g',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'barcode': barcode,
      'scanTime': scanTime.toIso8601String(),
      'servingSize': servingSize,
      'servingUnit': servingUnit,
    };
  }

  factory ScannedFood.fromJson(Map<String, dynamic> json) {
    return ScannedFood(
      name: json['name'],
      imageUrl: json['imageUrl'],
      calories: json['calories'].toDouble(),
      protein: json['protein'].toDouble(),
      carbs: json['carbs'].toDouble(),
      fat: json['fat'].toDouble(),
      fiber: json['fiber']?.toDouble() ?? 0,
      sugar: json['sugar']?.toDouble() ?? 0,
      barcode: json['barcode'],
      scanTime: DateTime.parse(json['scanTime']),
      servingSize: json['servingSize']?.toDouble() ?? 100,
      servingUnit: json['servingUnit'] ?? 'g',
    );
  }

  ScannedFood copyWith({
    String? name,
    String? imageUrl,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    String? barcode,
    DateTime? scanTime,
    double? servingSize,
    String? servingUnit,
  }) {
    return ScannedFood(
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      barcode: barcode ?? this.barcode,
      scanTime: scanTime ?? this.scanTime,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
    );
  }
} 