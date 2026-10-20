import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/expense_categories.dart';
import '../../models/expense_model.dart';
import '../../models/budget_model.dart';
import '../../services/budget_service.dart';
import '../../services/expense_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_format.dart';
import '../../utils/period_helper.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _budgetService = BudgetService();
  final _expenseService = ExpenseService();

  // S1: Period selector state (default 'Weekly')
  String _selectedPeriod = 'Weekly';

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
          final allExpenses = expSnap.data ?? [];

          return StreamBuilder<BudgetModel?>(
            stream: _budgetService.streamUserBudget(),
            builder: (context, budgetSnap) {
              final budget = budgetSnap.data;
              final hasBudget = budget != null;

              // G4 & S1: Filter expenses by selected period and compute totals (6.2: no end cutoff)
              final periodExpenses =
                  PeriodHelper.filterExpensesByPeriod(allExpenses, _selectedPeriod);
              final totalExpenses =
                  periodExpenses.fold(0.0, (sum, e) => sum + e.amount);
              final totalBudget =
                  PeriodHelper.getBudgetForPeriod(budget, _selectedPeriod);
              final remaining = totalBudget - totalExpenses;
              final isOver = remaining < 0;

              // 2.2: Division by zero safe progress calculation
              final progress = PeriodHelper.calculateProgress(
                spent: totalExpenses,
                totalBudget: totalBudget,
              );
              final progressColor = PeriodHelper.getProgressColor(
                remaining: remaining,
                progress: progress,
              );

              // Group period expenses by category
              final Map<String, double> byCategory = {};
              for (final e in periodExpenses) {
                byCategory[e.category] =
                    (byCategory[e.category] ?? 0) + e.amount;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // S1: Period selector chips (Daily / Weekly / Monthly)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: ['Daily', 'Weekly', 'Monthly'].map((period) {
                            final isSelected = _selectedPeriod == period;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text(
                                  period,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.surfaceHigh,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedPeriod = period;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // S2: Prominent Remaining Budget Card (Visual Focus)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isOver ? AppColors.danger : AppColors.border,
                              width: isOver ? 1.5 : 1.0,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 26,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      isOver
                                          ? 'Over Budget'
                                          : 'Remaining Budget',
                                      style: TextStyle(
                                        color: isOver
                                            ? AppColors.danger
                                            : AppColors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: progressColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isOver
                                                ? Icons.warning_amber_rounded
                                                : Icons.savings_rounded,
                                            size: 14,
                                            color: progressColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$_selectedPeriod View',
                                            style: TextStyle(
                                              color: progressColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Large Remaining Amount
                                Text(
                                  formatPeso(remaining),
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: isOver
                                        ? AppColors.danger
                                        : AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Progress Bar (height 10, rounded ends)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 10,
                                    backgroundColor: AppColors.surfaceHigh,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      progressColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      !hasBudget
                                          ? 'No budget set for $_selectedPeriod'
                                          : isOver
                                              ? 'Over budget'
                                              : '${(progress * 100).toStringAsFixed(1)}% of budget used',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (hasBudget)
                                      Text(
                                        isOver
                                            ? 'Over limit'
                                            : '${formatPeso(remaining)} left',
                                        style: TextStyle(
                                          color: isOver
                                              ? AppColors.danger
                                              : AppColors.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Summary Cards Row: Total Budget & Total Spent
                        Row(
                          children: [
                            _buildInfoCard(
                              label: 'Total Budget',
                              value: formatPeso(totalBudget),
                              color: AppColors.primary,
                              icon: Icons.account_balance_wallet_rounded,
                            ),
                            const SizedBox(width: 10),
                            _buildInfoCard(
                              label: 'Total Spent',
                              value: formatSpent(totalExpenses),
                              color: AppColors.warning,
                              icon: Icons.shopping_cart_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Spending by Category
                        Text(
                          'Spending by Category ($_selectedPeriod)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (periodExpenses.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: Text(
                              'No expenses recorded for this ${_selectedPeriod.toLowerCase()}.',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          ...ExpenseCategories.all
                              .where((cat) => byCategory.containsKey(cat.name))
                              .map((cat) {
                            final spent = byCategory[cat.name] ?? 0;
                            final catProgress = PeriodHelper.calculateProgress(
                              spent: spent,
                              totalBudget: totalBudget,
                            );
                            return _categoryRow(
                              cat.name,
                              cat.icon,
                              cat.color,
                              spent,
                              catProgress,
                            );
                          }),

                        const SizedBox(height: 24),

                        // Recent Expenses
                        if (allExpenses.isNotEmpty) ...[
                          const Text(
                            'Recent Expenses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...allExpenses.take(5).map((e) {
                            final cat = ExpenseCategories.fromName(e.category);
                            final isUpcoming = e.date.isAfter(DateTime.now());
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cat.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(cat.icon,
                                      color: cat.color, size: 20),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isUpcoming)
                                      Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.4),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.event_outlined,
                                              size: 10,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Upcoming',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  DateFormat('MMM dd').format(e.date),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  formatSpent(e.amount),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryRow(
    String name,
    IconData icon,
    Color color,
    double spent,
    double progress,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  formatSpent(spent),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
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
