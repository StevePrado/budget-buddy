import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/expense_categories.dart';
import '../../models/expense_model.dart';
import '../../services/budget_service.dart';
import '../../services/expense_service.dart';
import '../../theme/app_colors.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _budgetService = BudgetService();
  final _expenseService = ExpenseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expenseService.streamExpenses(),
        builder: (context, expSnap) {
          final expenses = expSnap.data ?? [];
          final totalExpenses =
              expenses.fold(0.0, (sum, e) => sum + e.amount);

          return StreamBuilder(
            stream: _budgetService.streamUserBudget(),
            builder: (context, budgetSnap) {
              final budget = budgetSnap.data;
              final totalBudget = budget?.activeTotalBudget ?? 0.0;
              final remaining = totalBudget - totalExpenses;
              final isOver = remaining < 0;
              final progress = totalBudget > 0
                  ? (totalExpenses / totalBudget).clamp(0.0, 1.0)
                  : 0.0;

              // Group expenses by category
              final Map<String, double> byCategory = {};
              for (final e in expenses) {
                byCategory[e.category] =
                    (byCategory[e.category] ?? 0) + e.amount;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Budget period label
                    if (budget != null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${budget.selectedPeriod} Budget Period',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Summary Cards Row
                    Row(
                      children: [
                        _summaryCard(
                            'Total Budget',
                            '₱${totalBudget.toStringAsFixed(2)}',
                            AppColors.primary,
                            Icons.account_balance_wallet_rounded),
                        const SizedBox(width: 10),
                        _summaryCard(
                            'Total Spent',
                            '₱${totalExpenses.toStringAsFixed(2)}',
                            AppColors.warning,
                            Icons.shopping_cart_rounded),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _summaryCard(
                      isOver ? 'Over Budget By' : 'Remaining',
                      '₱${remaining.abs().toStringAsFixed(2)}',
                      isOver ? AppColors.danger : AppColors.success,
                      isOver
                          ? Icons.warning_amber_rounded
                          : Icons.savings_rounded,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 20),

                    // Progress Bar
                    if (totalBudget > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Budget Used',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                                color: isOver
                                    ? AppColors.danger
                                    : progress > 0.8
                                        ? AppColors.warning
                                        : AppColors.success,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: AppColors.surfaceHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOver
                                ? AppColors.danger
                                : progress > 0.8
                                    ? AppColors.warning
                                    : AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Breakdown by Category
                    const Text('Spending by Category',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),

                    if (expenses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text('No expenses recorded yet.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    else
                      ...ExpenseCategories.all
                          .where((cat) =>
                              byCategory.containsKey(cat.name))
                          .map((cat) {
                        final spent = byCategory[cat.name] ?? 0;
                        final catProgress = totalBudget > 0
                            ? (spent / totalBudget).clamp(0.0, 1.0)
                            : 0.0;
                        return _categoryRow(
                            cat.name, cat.icon, cat.color, spent, catProgress);
                      }),

                    const SizedBox(height: 24),

                    // Recent Expenses
                    if (expenses.isNotEmpty) ...[
                      const Text('Recent Expenses',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      ...expenses.take(5).map((e) {
                        final cat = ExpenseCategories.fromName(e.category);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  cat.color.withValues(alpha: 0.15),
                              child: Icon(cat.icon,
                                  color: cat.color, size: 20),
                            ),
                            title: Text(e.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            subtitle: Text(
                                DateFormat('MMM dd').format(e.date),
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12)),
                            trailing: Text(
                              '₱${e.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _summaryCard(
      String label, String value, Color color, IconData icon,
      {bool fullWidth = false}) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (fullWidth) return card;
    return Expanded(child: card);
  }

  Widget _categoryRow(String name, IconData icon, Color color, double spent,
      double progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary))),
                Text('₱${spent.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceHigh,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
