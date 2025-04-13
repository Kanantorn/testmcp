import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppTheme extends ChangeNotifier {
  static bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  // Colors
  static final Color primaryColor = Colors.green[600]!;
  static final Color primaryColorLight = Colors.green[400]!;
  static final Color primaryColorDark = Colors.green[800]!;
  static final Color accentColor = Colors.orange[400]!;
  static final Color errorColor = Colors.red[500]!;
  static final Color successColor = Colors.green[400]!;
  
  // Text colors
  static const Color textColorPrimary = Color(0xFF212121);
  static const Color textColorSecondary = Color(0xFF757575);
  static const Color textColorHint = Color(0xFFBDBDBD);
  
  // Spacing
  static const double spacingExtraSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 32.0;
  
  // Font sizes
  static const double fontSizeExtraSmall = 10.0;
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeHeading = 22.0;
  static const double fontSizeExtraLarge = 28.0;
  
  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  // Light theme
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: spacingMedium,
            horizontal: spacingLarge,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(color: primaryColorLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.all(spacingMedium),
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontSize: fontSizeMedium,
          color: textColorPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeHeading,
          fontWeight: FontWeight.bold,
          color: textColorPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: textColorPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeSmall,
          color: textColorSecondary,
        ),
      ),
    );
  }
  
  // Dark theme (not fully implemented for now)
  static ThemeData darkTheme() {
    return ThemeData(
      primaryColor: primaryColorDark,
      colorScheme: ColorScheme.dark(
        primary: primaryColorDark,
        secondary: accentColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColorDark,
        foregroundColor: Colors.white,
      ),
      // Other theme settings would be similar to light theme but with dark colors
    );
  }
  
  // Get current theme based on mode
  ThemeData currentTheme() {
    return _isDarkMode ? darkTheme() : lightTheme();
  }
  
  // Static method to get AppTheme from context
  static AppTheme of(BuildContext context) {
    return Provider.of<AppTheme>(context, listen: false);
  }
} 