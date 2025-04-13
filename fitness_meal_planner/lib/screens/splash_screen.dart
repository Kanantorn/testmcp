import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/food_log_provider.dart';
import '../providers/meal_plan_provider.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Wait for a small delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Initialize providers
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
    final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
    
    // Load user data
    await userProvider.loadUser();
    
    // Load food log entries
    await foodLogProvider.loadEntries();
    
    // Load last meal plan
    await mealPlanProvider.loadLastMealPlan();
    
    setState(() {
      _isInitialized = true;
    });
    
    // Navigate to the appropriate screen
    if (userProvider.isUserSet) {
      // User already set up, go to home screen
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // User not set up, go to goal setting screen
      Navigator.of(context).pushReplacementNamed('/goals');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColorDark,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            const Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.white,
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // App name
            const Text(
              'Fitness Meal Planner',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTheme.fontSizeExtraLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingLarge),
            
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            // Loading text
            Text(
              _isInitialized ? 'Ready!' : 'Loading...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppTheme.fontSizeMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 