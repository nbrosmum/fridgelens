import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5409DA);
  static const Color secondary = Color(0xFF4E71FF);
  static const Color tertiary = Color(0xFF8DD8FF);
  static const Color background = Colors.white;
  static const Color error = Colors.red;
  static const Color success = Colors.green;
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle body = TextStyle(fontSize: 16, color: Colors.black87);

  static const TextStyle caption = TextStyle(fontSize: 14, color: Colors.grey);
}

class AppAssets {
  static const String logo = 'assets/logo.png';
}

class AppStrings {
  static const String appName = 'FridgeLens';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String createAccount = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
}

// Expiry/compartment logic for fridge items
const Map<String, Map<String, int>> defaultExpiryDays = {
  'chiller': {
    'Vegetables': 7,
    'Fruits': 7,
    'Dairy Products': 10,
    'Meat & Poultry': 3,
    'Bakery & Grains': 5,
    'Drinks & Beverages': 14,
    'Condiments & Sauces': 30,
    'Frozen Food': 2,
    'Other': 7,
  },
  'freezer': {
    'Vegetables': 60,
    'Fruits': 60,
    'Dairy Products': 30,
    'Meat & Poultry': 90,
    'Bakery & Grains': 30,
    'Drinks & Beverages': 60,
    'Condiments & Sauces': 90,
    'Frozen Food': 180,
    'Other': 60,
  },
};

Map<String, dynamic> getExpiryAndCompartment({
  required String fridgeType,
  required String category,
}) {
  String compartment = 'chiller';
  if (fridgeType == 'freezer') {
    compartment = 'freezer';
  } else if (fridgeType == 'both') {
    if (category == 'Meat & Poultry' || category == 'Frozen Food') {
      compartment = 'freezer';
    }
  }
  final days = defaultExpiryDays[compartment]?[category] ?? 7;
  final expiryDate = DateTime.now().add(Duration(days: days));
  final reminderDate = expiryDate.subtract(const Duration(days: 1));
  return {
    'compartment': compartment,
    'expiryDate': expiryDate,
    'reminderDate': reminderDate,
  };
}
