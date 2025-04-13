class User {
  String? id;
  String? name;
  int age;
  double weight; // in kg
  double height; // in cm
  String gender;
  String activityLevel;
  String goal;

  User({
    this.id,
    this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
    required this.goal,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      weight: json['weight'].toDouble(),
      height: json['height'].toDouble(),
      gender: json['gender'],
      activityLevel: json['activityLevel'],
      goal: json['goal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'activityLevel': activityLevel,
      'goal': goal,
    };
  }
  
  // Calculate daily calories using Mifflin-St Jeor equation
  double calculateDailyCalories() {
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }
    
    // Activity level multipliers
    double activityMultiplier;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'lightly active':
        activityMultiplier = 1.375;
        break;
      case 'moderately active':
        activityMultiplier = 1.55;
        break;
      case 'very active':
        activityMultiplier = 1.725;
        break;
      case 'extra active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.2;
    }
    
    double tdee = bmr * activityMultiplier;
    
    // Adjust based on goal
    switch (goal.toLowerCase()) {
      case 'muscle gain':
        return tdee + 300; // Caloric surplus
      case 'fat loss':
        return tdee - 500; // Caloric deficit
      case 'maintenance':
      default:
        return tdee;
    }
  }
  
  // Calculate macros based on goal
  Map<String, double> calculateMacros() {
    double dailyCalories = calculateDailyCalories();
    double proteinPercentage, carbsPercentage, fatsPercentage;
    
    // Set macro percentages based on goal
    switch (goal.toLowerCase()) {
      case 'muscle gain':
        proteinPercentage = 0.30; // 30%
        carbsPercentage = 0.45;   // 45%
        fatsPercentage = 0.25;    // 25%
        break;
      case 'fat loss':
        proteinPercentage = 0.40; // 40%
        carbsPercentage = 0.30;   // 30%
        fatsPercentage = 0.30;    // 30%
        break;
      case 'maintenance':
      default:
        proteinPercentage = 0.30; // 30%
        carbsPercentage = 0.40;   // 40%
        fatsPercentage = 0.30;    // 30%
    }
    
    // Calculate grams of each macro
    double proteinGrams = (dailyCalories * proteinPercentage) / 4; // 4 calories per gram
    double carbsGrams = (dailyCalories * carbsPercentage) / 4;     // 4 calories per gram
    double fatsGrams = (dailyCalories * fatsPercentage) / 9;      // 9 calories per gram
    
    return {
      'calories': dailyCalories,
      'protein': proteinGrams,
      'carbs': carbsGrams,
      'fats': fatsGrams,
    };
  }
} 