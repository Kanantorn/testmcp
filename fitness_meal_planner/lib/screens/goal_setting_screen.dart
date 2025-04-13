import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({Key? key}) : super(key: key);

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form values
  String _name = '';
  int _age = 30;
  double _weight = 70.0;
  double _height = 170.0;
  String _gender = 'Male';
  String _activityLevel = 'Moderately Active';
  String _goal = 'Muscle Gain';
  
  // Loading state
  bool _isLoading = false;
  
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
  
  // Save user profile
  void _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Create user object
        final user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _name,
          age: _age,
          weight: _weight,
          height: _height,
          gender: _gender,
          activityLevel: _activityLevel,
          goal: _goal,
        );
        
        // Save to provider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final result = await userProvider.saveUser(user);
        
        if (!mounted) return;
        
        if (result) {
          // Navigate to home screen
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save profile. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } catch (e) {
        // Show error
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Your Fitness Goals'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Introduction text
                    const Text(
                      'Let\'s set up your profile to create personalized meal plans',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        color: AppTheme.textColorSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: AppTheme.spacingLarge),
                    
                    // Name field
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _validateName,
                      onSaved: (value) => _name = value?.trim() ?? '',
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
                      initialValue: _age.toString(),
                      validator: _validateAge,
                      onSaved: (value) => _age = int.tryParse(value ?? '') ?? 30,
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
                      initialValue: _weight.toString(),
                      validator: _validateWeight,
                      onSaved: (value) => _weight = double.tryParse(value ?? '') ?? 70.0,
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
                      initialValue: _height.toString(),
                      validator: _validateHeight,
                      onSaved: (value) => _height = double.tryParse(value ?? '') ?? 170.0,
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
                                _gender = value ?? 'Male';
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
                                _gender = value ?? 'Female';
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
                          _activityLevel = value ?? 'Moderately Active';
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
                          _goal = value ?? 'Muscle Gain';
                        });
                      },
                    ),
                    
                    const SizedBox(height: AppTheme.spacingExtraLarge),
                    
                    // Save button
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 