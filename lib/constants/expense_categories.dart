import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
      ExpenseCategory('Food', Icons.restaurant_rounded, AppColors.warning);
  static const transportation = ExpenseCategory(
      'Transportation', Icons.directions_bus_rounded, AppColors.primary);
  static const school =
      ExpenseCategory('School', Icons.school_rounded, AppColors.secondary);
  static const loadInternet = ExpenseCategory(
      'Load/Internet', Icons.wifi_rounded, AppColors.success);
  static const entertainment = ExpenseCategory(
      'Entertainment', Icons.sports_esports_rounded, AppColors.danger);
  static const other = ExpenseCategory(
      'Other', Icons.category_rounded, AppColors.textSecondary);

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
