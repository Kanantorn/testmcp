import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/food_log_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/macro_progress_card.dart';
import '../models/meal.dart';
import 'meal_plan_screen.dart';
import 'food_log_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isGeneratingMealPlan = false;
  
  // Screen navigation
  final List<Widget> _screens = [
    const _HomeContent(),
    const MealPlanScreen(),
    const FoodLogScreen(),
    const ProfileScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final mealPlanProvider = Provider.of<MealPlanProvider>(context);
    
    // If user not set, navigate to goal setting screen
    if (!userProvider.isUserSet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/goals');
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Meal Planner'),
        actions: [
          if (_selectedIndex == 0 || _selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Generate New Meal Plan',
              onPressed: _isGeneratingMealPlan
                  ? null
                  : () async {
                      setState(() {
                        _isGeneratingMealPlan = true;
                      });
                      
                      try {
                        await mealPlanProvider.generateMealPlan(userProvider.user!);
                        
                        if (!mounted) return;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('New meal plan generated!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                        
                        // Switch to meal plan tab if on home tab
                        if (_selectedIndex == 0) {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        }
                      } catch (e) {
                        if (!mounted) return;
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isGeneratingMealPlan = false;
                          });
                        }
                      }
                    },
            ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textColorSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Meal Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank),
            label: 'Food Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final mealPlanProvider = Provider.of<MealPlanProvider>(context);
    final foodLogProvider = Provider.of<FoodLogProvider>(context);
    
    final user = userProvider.user;
    final mealPlan = mealPlanProvider.mealPlan;
    
    // Calculate target macros and today's consumed macros
    final targetMacros = userProvider.getUserMacros();
    final consumedMacros = foodLogProvider.getTotalMacrosForSelectedDate();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting and summary
          Text(
            'Hello, ${user?.name ?? 'Fitness Enthusiast'}!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          
          const SizedBox(height: AppTheme.spacingSmall),
          
          Text(
            'Goal: ${user?.goal ?? 'Not set'}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Today's Progress Section
          const Text(
            'Today\'s Progress',
            style: TextStyle(
              fontSize: AppTheme.fontSizeHeading,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Macro progress cards
          Row(
            children: [
              Expanded(
                child: MacroProgressCard(
                  title: 'Calories',
                  consumed: consumedMacros['calories'] ?? 0,
                  target: targetMacros['calories'] ?? 0,
                  unit: 'kcal',
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingSmall),
          
          Row(
            children: [
              Expanded(
                child: MacroProgressCard(
                  title: 'Protein',
                  consumed: consumedMacros['protein'] ?? 0,
                  target: targetMacros['protein'] ?? 0,
                  unit: 'g',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: MacroProgressCard(
                  title: 'Carbs',
                  consumed: consumedMacros['carbs'] ?? 0,
                  target: targetMacros['carbs'] ?? 0,
                  unit: 'g',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: MacroProgressCard(
                  title: 'Fats',
                  consumed: consumedMacros['fats'] ?? 0,
                  target: targetMacros['fats'] ?? 0,
                  unit: 'g',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Meal Plan Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Meal Plan',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeHeading,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MealPlanScreen(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Meal plan cards
          if (mealPlan == null || mealPlan.meals.isEmpty)
            _buildNoMealPlanCard(context)
          else
            Column(
              children: mealPlan.meals.map((meal) => 
                _buildMealCard(context, meal)
              ).toList(),
            ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Quick Links
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: AppTheme.fontSizeHeading,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          _buildQuickActionCards(context),
        ],
      ),
    );
  }
  
  Widget _buildNoMealPlanCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'No meal plan generated yet',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            const Text(
              'Generate a meal plan based on your fitness goals',
              style: TextStyle(
                color: AppTheme.textColorSecondary,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingMedium),
            
            ElevatedButton(
              onPressed: () async {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
                
                try {
                  await mealPlanProvider.generateMealPlan(userProvider.user!);
                } catch (e) {
                  if (!context.mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              child: const Text('Generate Meal Plan'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMealCard(BuildContext context, Meal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Macro summary
                Text(
                  '${meal.calculateTotalMacros()['calories']?.toInt() ?? 0} kcal',
                  style: const TextStyle(
                    color: AppTheme.textColorSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const Divider(),
            
            // Food items (limited to 3 with 'more' text if needed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: meal.items.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.food.name),
                      Text(
                        '${item.quantity.toInt()} ${item.food.servingUnit}',
                        style: const TextStyle(
                          color: AppTheme.textColorSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            if (meal.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '+ ${meal.items.length - 3} more items',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FoodLogScreen(initialTab: 0),
                ),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.accentColor,
                      size: 40,
                    ),
                    SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Log Food',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.settings,
                      color: AppTheme.accentColor,
                      size: 40,
                    ),
                    SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Edit Goals',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 