import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/food_log_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form values
  String? _name;
  int? _age;
  double? _weight;
  double? _height;
  String? _gender;
  String? _activityLevel;
  String? _goal;
  
  // Loading state
  bool _isLoading = false;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  // Load user data from provider
  void _loadUserData() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      setState(() {
        _name = user.name;
        _age = user.age;
        _weight = user.weight;
        _height = user.height;
        _gender = user.gender;
        _activityLevel = user.activityLevel;
        _goal = user.goal;
      });
    }
  }
  
  // Form validators
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }
  
  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid number';
    }
    if (age < 18 || age > 100) {
      return 'Age must be between 18 and 100';
    }
    return null;
  }
  
  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your weight';
    }
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid number';
    }
    if (weight < 30 || weight > 250) {
      return 'Weight must be between 30 and 250 kg';
    }
    return null;
  }
  
  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your height';
    }
    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter a valid number';
    }
    if (height < 120 || height > 220) {
      return 'Height must be between 120 and 220 cm';
    }
    return null;
  }
  
  // Save updated profile
  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Get current user and update with form values
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.user;
        
        if (user != null) {
          // Create updated user
          final updatedUser = User(
            id: user.id,
            name: _name,
            age: _age!,
            weight: _weight!,
            height: _height!,
            gender: _gender!,
            activityLevel: _activityLevel!,
            goal: _goal!,
          );
          
          // Save to provider
          final result = await userProvider.saveUser(updatedUser);
          
          if (!mounted) return;
          
          if (result) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            
            setState(() {
              _isEditing = false;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile. Please try again.'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
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
            _isLoading = false;
          });
        }
      }
    }
  }
  
  // Clear user data and reset app state
  void _resetApp() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App'),
        content: const Text(
          'This will clear all your data, including your profile, meal plans, and food logs. '
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                // Clear providers
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                final mealPlanProvider = Provider.of<MealPlanProvider>(context, listen: false);
                final foodLogProvider = Provider.of<FoodLogProvider>(context, listen: false);
                
                await userProvider.clearUser();
                mealPlanProvider.clearMealPlan();
                await foodLogProvider.clearEntriesForSelectedDate();
                
                if (!mounted) return;
                
                // Navigate to goal setting screen
                Navigator.of(context).pushReplacementNamed('/goals');
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
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: _isEditing ? _buildEditForm(user) : _buildProfileView(user),
            ),
    );
  }
  
  Widget _buildProfileView(User user) {
    // Calculate user's calorie and macro needs
    final calorieNeeds = user.calculateDailyCalories().toInt();
    final macros = user.calculateMacros();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile header
        const CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.primaryColorLight,
          child: Icon(
            Icons.person,
            size: 60,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        Text(
          user.name ?? 'Fitness Enthusiast',
          style: const TextStyle(
            fontSize: AppTheme.fontSizeExtraLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        Text(
          user.goal,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingLarge),
        
        // Nutrition summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutrition Summary',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const Divider(),
                
                _buildInfoRow('Daily Caloric Needs:', '$calorieNeeds kcal'),
                _buildInfoRow('Protein Target:', '${macros['protein']?.toInt() ?? 0} g'),
                _buildInfoRow('Carbs Target:', '${macros['carbs']?.toInt() ?? 0} g'),
                _buildInfoRow('Fats Target:', '${macros['fats']?.toInt() ?? 0} g'),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Profile details card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const Divider(),
                
                _buildInfoRow('Age:', '${user.age} years'),
                _buildInfoRow('Weight:', '${user.weight} kg'),
                _buildInfoRow('Height:', '${user.height} cm'),
                _buildInfoRow('Gender:', user.gender),
                _buildInfoRow('Activity Level:', user.activityLevel),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingLarge),
        
        // Edit button
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Reset app button
        TextButton.icon(
          onPressed: _resetApp,
          icon: const Icon(Icons.refresh, color: AppTheme.errorColor),
          label: const Text(
            'Reset App',
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEditForm(User user) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: AppTheme.fontSizeHeading,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Name field
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
            ),
            initialValue: user.name,
            textCapitalization: TextCapitalization.words,
            validator: _validateName,
            onSaved: (value) => _name = value?.trim(),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Age field
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Age (years)',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            initialValue: user.age.toString(),
            validator: _validateAge,
            onSaved: (value) => _age = int.tryParse(value ?? ''),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Weight field
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              prefixIcon: Icon(Icons.monitor_weight),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            initialValue: user.weight.toString(),
            validator: _validateWeight,
            onSaved: (value) => _weight = double.tryParse(value ?? ''),
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Height field
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              prefixIcon: Icon(Icons.height),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            initialValue: user.height.toString(),
            validator: _validateHeight,
            onSaved: (value) => _height = double.tryParse(value ?? ''),
          ),
          
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Gender selection
          const Text(
            'Gender',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Male'),
                  value: 'Male',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Female'),
                  value: 'Female',
                  groupValue: _gender,
                  onChanged: (value) {
                    setState(() {
                      _gender = value;
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Activity level selection
          const Text(
            'Activity Level',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.fitness_center),
            ),
            value: _activityLevel,
            items: const [
              DropdownMenuItem(value: 'Sedentary', child: Text('Sedentary (little or no exercise)')),
              DropdownMenuItem(value: 'Lightly Active', child: Text('Lightly Active (light exercise 1-3 days/week)')),
              DropdownMenuItem(value: 'Moderately Active', child: Text('Moderately Active (moderate exercise 3-5 days/week)')),
              DropdownMenuItem(value: 'Very Active', child: Text('Very Active (hard exercise 6-7 days/week)')),
              DropdownMenuItem(value: 'Extra Active', child: Text('Extra Active (very hard exercise & physical job)')),
            ],
            onChanged: (value) {
              setState(() {
                _activityLevel = value;
              });
            },
          ),
          
          const SizedBox(height: AppTheme.spacingMedium),
          
          // Fitness goal selection
          const Text(
            'Fitness Goal',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.track_changes),
            ),
            value: _goal,
            items: const [
              DropdownMenuItem(value: 'Muscle Gain', child: Text('Muscle Gain')),
              DropdownMenuItem(value: 'Fat Loss', child: Text('Fat Loss')),
              DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
            ],
            onChanged: (value) {
              setState(() {
                _goal = value;
              });
            },
          ),
          
          const SizedBox(height: AppTheme.spacingExtraLarge),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _loadUserData(); // Reset form values
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textColorSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 