import 'package:flutter/material.dart';
import 'dart:convert';
import 'mcp_test/mcp_test_runner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MCP Test App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.light(
          primary: Colors.green,
          secondary: Colors.orange,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _result = '';
  Map<String, dynamic>? _mealPlan;

  Future<void> _testMcpIntegration() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _mealPlan = null;
    });

    try {
      // Call the MCP test runner
      final result = await MCPTestRunner.testMCPIntegration();
      
      setState(() {
        _isLoading = false;
        if (result['status'] == 'success') {
          _result = 'MCP Integration Test Successful\n\n${result['message']}';
          _mealPlan = result['meal_plan'];
        } else {
          _result = 'MCP Integration Test Failed\n\n${result['message']}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Test App'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to the MCP Test App',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testMcpIntegration,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Test MCP Integration'),
                ),
                const SizedBox(height: 30),
                if (_result.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _result,
                      style: const TextStyle(fontSize: 16.0),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_mealPlan != null) ...[
                  const SizedBox(height: 30),
                  const Text(
                    'Generated Meal Plan',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMealPlanView(_mealPlan!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMealPlanView(Map<String, dynamic> mealPlan) {
    final meals = mealPlan['meals'] as List;
    final totalMacros = mealPlan['total_macros'] as Map<String, dynamic>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display total macros
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Nutrition',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Calories: ${totalMacros['calories']} kcal'),
                Text('Protein: ${totalMacros['protein']} g'),
                Text('Carbs: ${totalMacros['carbs']} g'),
                Text('Fats: ${totalMacros['fats']} g'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Display each meal
        ...meals.map((meal) {
          final mealName = meal['name'] as String;
          final items = meal['items'] as List;
          final macros = meal['macros'] as Map<String, dynamic>;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealName,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Food items
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['food_name'] as String),
                          Text('${item['quantity']} ${item['unit']}'),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Meal macros
                  Text('Calories: ${macros['calories']} kcal'),
                  Text('Protein: ${macros['protein']} g'),
                  Text('Carbs: ${macros['carbs']} g'),
                  Text('Fats: ${macros['fats']} g'),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
} 