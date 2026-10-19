import 'package:flutter/material.dart';

// Single Expense Category Model
class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.name, this.icon, this.color);
}

// Student Expense Categories
// Teammates: Use this for category dropdowns, filter chips, and expense list icons!
class ExpenseCategories {
  ExpenseCategories._();

  static const food =
      ExpenseCategory('Food', Icons.restaurant_rounded, Color(0xFFFFC53D)); // yellow
  static const transportation = ExpenseCategory(
      'Transportation', Icons.directions_bus_rounded, Color(0xFF4C8DFF)); // blue
  static const school =
      ExpenseCategory('School', Icons.school_rounded, Color(0xFF8B7CFF)); // purple
  static const loadInternet = ExpenseCategory(
      'Load/Internet', Icons.wifi_rounded, Color(0xFFFF9F43)); // orange
  static const entertainment = ExpenseCategory(
      'Entertainment', Icons.sports_esports_rounded, Color(0xFFFF7EB6)); // pink
  static const other = ExpenseCategory(
      'Other', Icons.category_rounded, Color(0xFFA5B0D6)); // light slate gray

  // List of all expense categories
  static const List<ExpenseCategory> all = [
    food,
    transportation,
    school,
    loadInternet,
    entertainment,
    other,
  ];

  // List of category name strings for dropdowns
  static List<String> get names => all.map((c) => c.name).toList();

  // Helper function to find a category by name saved in Firestore
  static ExpenseCategory fromName(String name) =>
      all.firstWhere((c) => c.name == name, orElse: () => other);
}
