import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../theme/app_colors.dart';

class PeriodHelper {
  PeriodHelper._();

  /// Filters a list of expenses according to the selected period:
  /// - Daily: on or after today 00:00:00 (no end cutoff)
  /// - Weekly: on or after Monday of this week 00:00:00 (no end cutoff)
  /// - Monthly: on or after the 1st of this month 00:00:00 (no end cutoff)
  static List<ExpenseModel> filterExpensesByPeriod(
    List<ExpenseModel> expenses,
    String period,
  ) {
    final now = DateTime.now();

    if (period == 'Daily') {
      final startOfToday = DateTime(now.year, now.month, now.day);
      return expenses.where((e) {
        return !e.date.isBefore(startOfToday);
      }).toList();
    } else if (period == 'Weekly') {
      // Dart DateTime: Monday is 1, Sunday is 7
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
      return expenses.where((e) {
        return !e.date.isBefore(startOfWeek);
      }).toList();
    } else if (period == 'Monthly') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      return expenses.where((e) {
        return !e.date.isBefore(startOfMonth);
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

  /// Calculates progress (0.0 to 1.0) safely avoiding NaN/Infinity (2.2):
  /// If budget <= 0: progress = 0 when spent == 0, and progress = 1 (full) when spent > 0.
  static double calculateProgress({
    required double spent,
    required double totalBudget,
  }) {
    if (totalBudget <= 0) {
      return spent > 0 ? 1.0 : 0.0;
    }
    final p = spent / totalBudget;
    if (p.isNaN || p.isInfinite) {
      return spent > 0 ? 1.0 : 0.0;
    }
    return p.clamp(0.0, 1.0);
  }

  /// Returns progress indicator color based on budget health:
  /// - Over budget (remaining < 0): AppColors.danger (red)
  /// - Near limit (>=80% and remaining >= 0): AppColors.warning (yellow)
  /// - Under budget (<80%): AppColors.success (mint green)
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
