class Food {
  final int id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final double servingSize;
  final String servingUnit;
  final String category;

  Food({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.servingSize,
    required this.servingUnit,
    required this.category,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      calories: json['calories'].toDouble(),
      protein: json['protein'].toDouble(),
      carbs: json['carbs'].toDouble(),
      fats: json['fats'].toDouble(),
      servingSize: json['serving_size'].toDouble(),
      servingUnit: json['serving_unit'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'serving_size': servingSize,
      'serving_unit': servingUnit,
      'category': category,
    };
  }

  // Calculate macros based on a specific portion size
  Map<String, double> calculateMacrosForPortion(double portionSize) {
    double multiplier = portionSize / servingSize;
    return {
      'calories': calories * multiplier,
      'protein': protein * multiplier,
      'carbs': carbs * multiplier,
      'fats': fats * multiplier,
    };
  }
} 