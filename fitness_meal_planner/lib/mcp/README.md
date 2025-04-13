# MCP Sequential Thinking for Meal Planning

This directory contains the implementation of the Model Context Protocol (MCP) Sequential Thinking for the Fitness Meal Planner app. The MCP Sequential Thinking pattern is used for generating personalized meal plans based on user profiles and nutritional targets.

## Overview

The implementation includes:

1. `sequential_thinking_task.dart` - Defines the meal planning task and formats user data for prompting
2. `sequential_thinking_runner.dart` - Handles the execution of the sequential thinking process
3. `direct_mcp_runner.dart` - Provides direct communication with the MCP server via stdio
4. `direct_test_client.dart` - A test client that can be run to test the MCP integration

## How it Works

The meal planning algorithm uses sequential thinking to:

1. Calculate meal distribution (breakfast, lunch, dinner, snack)
2. Categorize available foods
3. Select appropriate foods for each meal based on nutritional targets
4. Calculate portion sizes to meet macronutrient goals
5. Generate a complete meal plan with nutritional breakdown

## Integration

For real-world implementation with an actual MCP Sequential Thinking server:

1. Install the MCP server:
   ```
   npm install -g @modelcontextprotocol/server-sequential-thinking
   ```

2. Start the MCP server:
   ```
   npx @modelcontextprotocol/server-sequential-thinking
   ```

3. Run the direct test client:
   ```
   dart run lib/mcp/direct_test_client.dart
   ```

## Testing the Integration

There are two ways to test the MCP integration:

### 1. Using the Direct Test Client

1. First, start the MCP Sequential Thinking server in a terminal:
   ```
   npx @modelcontextprotocol/server-sequential-thinking
   ```

2. Then, run the direct test client in the same terminal session:
   ```
   dart run lib/mcp/direct_test_client.dart
   ```

This method communicates directly with the MCP server via stdio, allowing you to test the integration without any intermediate layers.

### 2. Using the Sequential Thinking Runner

The `MCPSequentialThinkingRunner` class provides methods for integrating with the MCP server in your Flutter app:

```dart
// Get user profile and calculate target macros
Map<String, dynamic> userProfile = user.toJson();
Map<String, double> targetMacros = user.calculateMacros();

// Get available foods
List<Map<String, dynamic>> availableFoods = 
    foods.map((f) => f.toJson()).toList();

// Generate meal plan
Map<String, dynamic> result = await MCPSequentialThinkingRunner.generateMealPlan(
  userProfile: userProfile,
  targetMacros: targetMacros,
  availableFoods: availableFoods,
);

// Extract meal plan data
Map<String, dynamic> mealPlanData = result['meal_plan'];
```

## Fallback Mechanism

The current implementation includes a fallback mechanism that generates meal plans locally when the MCP server is not available. This ensures the app remains functional even without the MCP server connection.