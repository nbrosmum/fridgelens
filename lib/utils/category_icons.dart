import 'package:flutter/material.dart';

class CategoryIcons {
  static IconData getIconForCategory(String category) {
    switch (category) {
      case 'Vegetables':
        return Icons.eco;
      case 'Fruits':
        return Icons.apple;
      case 'Dairy Products':
        return Icons.egg_alt;
      case 'Meat & Poultry':
        return Icons.restaurant_menu;
      case 'Bakery & Grains':
        return Icons.bakery_dining;
      case 'Drinks & Beverages':
        return Icons.local_drink;
      case 'Condiments & Sauces':
        return Icons.soup_kitchen;
      case 'Frozen Food':
        return Icons.ac_unit;
      case 'Other':
      default:
        return Icons.shopping_basket;
    }
  }

  static Color getColorForCategory(String category) {
    switch (category) {
      case 'Vegetables':
        return Colors.green;
      case 'Fruits':
        return Colors.orange;
      case 'Dairy Products':
        return Colors.blue[200]!;
      case 'Meat & Poultry':
        return Colors.red[300]!;
      case 'Bakery & Grains':
        return Colors.brown[300]!;
      case 'Drinks & Beverages':
        return Colors.lightBlue;
      case 'Condiments & Sauces':
        return Colors.deepOrange[300]!;
      case 'Frozen Food':
        return Colors.cyan;
      case 'Other':
      default:
        return Colors.grey;
    }
  }
}
