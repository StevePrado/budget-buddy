import 'package:budget_buddy/models/budget_model.dart';
import 'package:budget_buddy/models/expense_model.dart';
import 'package:budget_buddy/theme/app_colors.dart';
import 'package:budget_buddy/utils/period_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeriodHelper tests', () {
    final now = DateTime.now();

    final todayExpense = ExpenseModel(
      id: '1',
      userId: 'u1',
      name: 'Lunch',
      amount: 150,
      category: 'Food',
      date: DateTime(now.year, now.month, now.day, 12, 0),
    );

    final thisWeekExpense = ExpenseModel(
      id: '2',
      userId: 'u1',
      name: 'Notebooks',
      amount: 300,
      category: 'School',
      date: DateTime(now.year, now.month, now.day).subtract(
        Duration(days: (now.weekday - 1).clamp(0, 6)),
      ),
    );

    final oldExpense = ExpenseModel(
      id: '3',
      userId: 'u1',
      name: 'Old Shoes',
      amount: 1200,
      category: 'Other',
      date: DateTime(2021, 1, 1),
    );

    final list = [todayExpense, thisWeekExpense, oldExpense];

    test('filterExpensesByPeriod filters Daily correctly', () {
      final daily = PeriodHelper.filterExpensesByPeriod(list, 'Daily');
      expect(daily.any((e) => e.id == '1'), isTrue);
      expect(daily.any((e) => e.id == '3'), isFalse);
    });

    test('filterExpensesByPeriod filters Weekly correctly', () {
      final weekly = PeriodHelper.filterExpensesByPeriod(list, 'Weekly');
      expect(weekly.any((e) => e.id == '1'), isTrue);
      expect(weekly.any((e) => e.id == '2'), isTrue);
      expect(weekly.any((e) => e.id == '3'), isFalse);
    });

    test('calculatePeriodTotal sums expenses for period', () {
      final total = PeriodHelper.calculatePeriodTotal(list, 'Daily');
      expect(total >= 150, isTrue);
    });

    test('getBudgetForPeriod returns correct allowance', () {
      final budget = BudgetModel(
        userId: 'u1',
        dailyBudget: 200,
        weeklyBudget: 1400,
        monthlyBudget: 6000,
      );

      expect(PeriodHelper.getBudgetForPeriod(budget, 'Daily'), 200);
      expect(PeriodHelper.getBudgetForPeriod(budget, 'Weekly'), 1400);
      expect(PeriodHelper.getBudgetForPeriod(budget, 'Monthly'), 6000);
    });

    test('getProgressColor returns correct status colors', () {
      expect(
        PeriodHelper.getProgressColor(remaining: -10, progress: 1.1),
        AppColors.danger,
      );
      expect(
        PeriodHelper.getProgressColor(remaining: 100, progress: 0.85),
        AppColors.warning,
      );
      expect(
        PeriodHelper.getProgressColor(remaining: 500, progress: 0.5),
        AppColors.success,
      );
    });
  });
}
