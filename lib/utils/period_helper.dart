import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../theme/app_colors.dart';

class PeriodHelper {
  PeriodHelper._();

  /// Filters a list of expenses according to the selected period:
  /// - Daily: expenses dated today (00:00:00 to 23:59:59.999)
  /// - Weekly: from Monday of this week until the end of today
  /// - Monthly: from the 1st of this month until the end of today
  static List<ExpenseModel> filterExpensesByPeriod(
    List<ExpenseModel> expenses,
    String period,
  ) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    if (period == 'Daily') {
      final startOfToday = DateTime(now.year, now.month, now.day);
      return expenses.where((e) {
        return !e.date.isBefore(startOfToday) && !e.date.isAfter(endOfToday);
      }).toList();
    } else if (period == 'Weekly') {
      // Dart DateTime: Monday is 1, Sunday is 7
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return expenses.where((e) {
        return !e.date.isBefore(startOfWeek) && !e.date.isAfter(endOfToday);
      }).toList();
    } else if (period == 'Monthly') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      return expenses.where((e) {
        return !e.date.isBefore(startOfMonth) && !e.date.isAfter(endOfToday);
      }).toList();
    }
    return expenses;
  }

  /// Calculates total expenses sum for the given period
  static double calculatePeriodTotal(List<ExpenseModel> expenses, String period) {
    final filtered = filterExpensesByPeriod(expenses, period);
    return filtered.fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Returns the budget allowance corresponding to the specified period
  static double getBudgetForPeriod(BudgetModel? budget, String period) {
    if (budget == null) return 0.0;
    switch (period) {
      case 'Daily':
        return budget.dailyBudget;
      case 'Weekly':
        return budget.weeklyBudget;
      case 'Monthly':
      default:
        return budget.monthlyBudget;
    }
  }

  /// Returns progress indicator color based on budget health:
  /// - Under budget (<80%): AppColors.success (mint green)
  /// - Near limit (>=80% and remaining >= 0): AppColors.warning (yellow)
  /// - Over budget (remaining < 0): AppColors.danger (red)
  static Color getProgressColor({
    required double remaining,
    required double progress,
  }) {
    if (remaining < 0) {
      return AppColors.danger;
    }
    if (progress >= 0.8) {
      return AppColors.warning;
    }
    return AppColors.success;
  }
}
