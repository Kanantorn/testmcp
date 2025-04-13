import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'providers/user_provider.dart';
import 'providers/meal_plan_provider.dart';
import 'providers/food_log_provider.dart';
import 'providers/food_scan_provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/goal_setting_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/food_scan_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/food_log_screen.dart';
import 'screens/meal_plan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => FoodLogProvider()),
        ChangeNotifierProvider(create: (_) => FoodScanProvider()),
      ],
      child: MaterialApp(
        title: 'Fitness Meal Planner',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const MainNavigationScreen(),
          '/goals': (context) => const GoalSettingScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  static final List<Widget> _screens = [
    const HomeScreen(),
    const MealPlanScreen(),
    const FoodScanScreen(),
    const FoodLogScreen(),
    const ProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu_outlined),
                activeIcon: Icon(Icons.restaurant_menu),
                label: 'Plan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_outlined),
                activeIcon: Icon(Icons.camera_alt),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: 'Log',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedIndex == 2 
          ? FloatingActionButton(
              onPressed: () {
                // Use the provider to trigger the food scanning
                final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
                // Show a bottom sheet with options
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppTheme.borderRadiusLarge),
                    ),
                  ),
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTheme.borderRadiusLarge),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Scan Food',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildScanOption(
                              context,
                              icon: Icons.camera_alt_rounded,
                              label: 'Camera',
                              onTap: () {
                                Navigator.pop(context);
                                foodScanProvider.pickImageAndScan(ImageSource.camera);
                              },
                            ),
                            _buildScanOption(
                              context,
                              icon: Icons.photo_library_rounded,
                              label: 'Gallery',
                              onTap: () {
                                Navigator.pop(context);
                                foodScanProvider.pickImageAndScan(ImageSource.gallery);
                              },
                            ),
                            _buildScanOption(
                              context,
                              icon: Icons.qr_code_scanner_rounded,
                              label: 'Barcode',
                              onTap: () {
                                Navigator.pop(context);
                                foodScanProvider.scanBarcode('123456789');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Icon(Icons.camera_alt),
            ) 
          : null,
    );
  }
  
  Widget _buildScanOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
} 