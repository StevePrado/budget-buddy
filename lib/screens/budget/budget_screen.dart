import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
import '../../models/expense_model.dart';
import '../../services/budget_service.dart';
import '../../services/expense_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_format.dart';
import '../../utils/period_helper.dart';
import '../../widgets/budget_alert_banner.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();
  final ExpenseService _expenseService = ExpenseService();

  // Screen view period state ('Daily', 'Weekly', 'Monthly')
  String _selectedViewPeriod = 'Weekly';

  // Helper string formatter for synced auto-calculated fields
  String _formatSynced(double value) {
    if (value <= 0) return '';
    return NumberFormat('#,##0.00').format(value);
  }

  // Open Dialog to edit Daily, Weekly, and Monthly budgets
  void _showEditBudgetDialog(BudgetModel currentBudget) {
    final formKey = GlobalKey<FormState>();

    final dailyController = TextEditingController(
      text: currentBudget.dailyBudget > 0
          ? formatAmountForInput(currentBudget.dailyBudget)
          : '',
    );
    final weeklyController = TextEditingController(
      text: currentBudget.weeklyBudget > 0
          ? formatAmountForInput(currentBudget.weeklyBudget)
          : '',
    );
    final monthlyController = TextEditingController(
      text: currentBudget.monthlyBudget > 0
          ? formatAmountForInput(currentBudget.monthlyBudget)
          : '',
    );

    bool isSaving = false;
    bool isSyncing = false;

    // 2 & D3: Auto-sync between Daily, Weekly, and Monthly controllers
    void onDailyChanged(String text) {
      if (isSyncing) return;
      isSyncing = true;
      final val = parsePeso(text);
      if (val != null && val > 0) {
        // Daily edited -> Weekly = Daily x 7, Monthly = Daily x 30
        weeklyController.text = _formatSynced(val * 7);
        weeklyController.selection = TextSelection.collapsed(
          offset: weeklyController.text.length,
        );
        monthlyController.text = _formatSynced(val * 30);
        monthlyController.selection = TextSelection.collapsed(
          offset: monthlyController.text.length,
        );
      }
      isSyncing = false;
    }

    void onWeeklyChanged(String text) {
      if (isSyncing) return;
      isSyncing = true;
      final val = parsePeso(text);
      if (val != null && val > 0) {
        // Weekly edited -> Daily = Weekly / 7, Monthly = Weekly x 4
        dailyController.text = _formatSynced(val / 7);
        dailyController.selection = TextSelection.collapsed(
          offset: dailyController.text.length,
        );
        monthlyController.text = _formatSynced(val * 4);
        monthlyController.selection = TextSelection.collapsed(
          offset: monthlyController.text.length,
        );
      }
      isSyncing = false;
    }

    void onMonthlyChanged(String text) {
      if (isSyncing) return;
      isSyncing = true;
      final val = parsePeso(text);
      if (val != null && val > 0) {
        // Monthly edited -> Daily = Monthly / 30, Weekly = (Monthly / 30) x 7
        dailyController.text = _formatSynced(val / 30);
        dailyController.selection = TextSelection.collapsed(
          offset: dailyController.text.length,
        );
        weeklyController.text = _formatSynced((val / 30) * 7);
        weeklyController.selection = TextSelection.collapsed(
          offset: weeklyController.text.length,
        );
      }
      isSyncing = false;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Set Student Budget',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enter your allowance limits below.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Daily Field
                          _buildDialogAmountField(
                            controller: dailyController,
                            label: 'Daily Budget (₱)',
                            onChanged: onDailyChanged,
                          ),
                          const SizedBox(height: 14),

                          // Weekly Field
                          _buildDialogAmountField(
                            controller: weeklyController,
                            label: 'Weekly Budget (₱)',
                            onChanged: onWeeklyChanged,
                          ),
                          const SizedBox(height: 14),

                          // Monthly Field
                          _buildDialogAmountField(
                            controller: monthlyController,
                            label: 'Monthly Budget (₱)',
                            onChanged: onMonthlyChanged,
                          ),
                          const SizedBox(height: 12),

                          // Helper text
                          const Text(
                            'Changing one budget updates the others. You can still edit them.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                ),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: isSaving
                                    ? null
                                    : () {
                                        dailyController.clear();
                                        weeklyController.clear();
                                        monthlyController.clear();
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                ),
                                child: const Text('Reset'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  minimumSize: const Size(120, 46),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        // 3 & D4: Validation on Save
                                        final daily =
                                            parsePeso(dailyController.text);
                                        final weekly =
                                            parsePeso(weeklyController.text);
                                        final monthly =
                                            parsePeso(monthlyController.text);

                                        if (daily == null ||
                                            weekly == null ||
                                            monthly == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please fill in all budget fields with valid amounts.',
                                              ),
                                              backgroundColor: AppColors.danger,
                                            ),
                                          );
                                          return;
                                        }

                                        if (daily <= 0 ||
                                            weekly <= 0 ||
                                            monthly <= 0) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Budget amounts must be greater than zero.',
                                              ),
                                              backgroundColor: AppColors.danger,
                                            ),
                                          );
                                          return;
                                        }

                                        if (!(daily <= weekly &&
                                            weekly <= monthly)) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Daily must be less than or equal to Weekly, and Weekly less than or equal to Monthly',
                                              ),
                                              backgroundColor: AppColors.danger,
                                            ),
                                          );
                                          return;
                                        }

                                        setDialogState(() => isSaving = true);
                                        try {
                                          await _budgetService.saveBudget(
                                            dailyBudget: daily,
                                            weeklyBudget: weekly,
                                            monthlyBudget: monthly,
                                            selectedPeriod:
                                                currentBudget.selectedPeriod,
                                          );
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Budget saved successfully!',
                                                ),
                                                backgroundColor:
                                                    AppColors.success,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setDialogState(
                                              () => isSaving = false);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Error saving budget: $e',
                                                ),
                                                backgroundColor:
                                                    AppColors.danger,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save Budget',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogAmountField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: const [CommaNumberInputFormatter()],
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        fillColor: AppColors.surfaceHigh,
        filled: true,
        prefixIcon: const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            '₱',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Setup & Summary'),
        centerTitle: true,
      ),
      body: StreamBuilder<BudgetModel>(
        stream: _budgetService.streamUserBudget(),
        builder: (context, budgetSnapshot) {
          if (budgetSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (budgetSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading budget: ${budgetSnapshot.error}',
                style: const TextStyle(color: AppColors.danger),
              ),
            );
          }

          final budget = budgetSnapshot.data ??
              BudgetModel(
                userId: _budgetService.currentUserId,
                dailyBudget: 0,
                weeklyBudget: 0,
                monthlyBudget: 0,
              );

          // Stream all expenses to calculate period expenses accurately (G4)
          return StreamBuilder<List<ExpenseModel>>(
            stream: _expenseService.streamExpenses(),
            builder: (context, expenseSnapshot) {
              final allExpenses = expenseSnapshot.data ?? [];

              // Calculate metrics based on selected view period
              final periodExpenses = PeriodHelper.calculatePeriodTotal(
                allExpenses,
                _selectedViewPeriod,
              );
              final totalBudget = PeriodHelper.getBudgetForPeriod(
                budget,
                _selectedViewPeriod,
              );
              final remainingBudget = totalBudget - periodExpenses;
              final isOverBudget = remainingBudget < 0;

              final progress = totalBudget > 0
                  ? (periodExpenses / totalBudget).clamp(0.0, 1.0)
                  : 0.0;
              final progressColor = PeriodHelper.getProgressColor(
                remaining: remainingBudget,
                progress: progress,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Period Selector Chips (Daily / Weekly / Monthly View)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: ['Daily', 'Weekly', 'Monthly'].map((period) {
                            final isSelected = _selectedViewPeriod == period;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: ChoiceChip(
                                label: Text(
                                  '$period View',
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
                                      _selectedViewPeriod = period;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // On-App Budget Alert Banner (when student exceeds budget)
                        if (isOverBudget && totalBudget > 0)
                          BudgetAlertBanner(
                            period: _selectedViewPeriod,
                            budget: totalBudget,
                            spent: periodExpenses,
                            onAction: () => _showEditBudgetDialog(budget),
                          ),

                        // 1. BUDGET SUMMARY CARD
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Budget Summary ($_selectedViewPeriod)',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: progressColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isOverBudget
                                            ? Icons.warning_amber_rounded
                                            : Icons.account_balance_wallet_rounded,
                                        color: progressColor,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 24,
                                  color: AppColors.border,
                                ),
                                _buildSummaryRow(
                                  label: 'Total Budget',
                                  amountText: formatPeso(totalBudget),
                                  color: AppColors.textPrimary,
                                  isBold: true,
                                ),
                                const SizedBox(height: 10),
                                _buildSummaryRow(
                                  label: 'Total Expenses',
                                  amountText: formatSpent(periodExpenses),
                                  color: AppColors.warning,
                                ),
                                const Divider(
                                  height: 24,
                                  color: AppColors.border,
                                ),
                                _buildSummaryRow(
                                  label: isOverBudget
                                      ? 'Over Budget'
                                      : 'Remaining Budget',
                                  amountText: formatPeso(remainingBudget),
                                  color: isOverBudget
                                      ? AppColors.danger
                                      : AppColors.success,
                                  isBold: true,
                                  fontSize: 20,
                                ),
                                const SizedBox(height: 16),
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
                                Text(
                                  totalBudget == 0
                                      ? 'Tap "Edit Budgets" below to set your allowance.'
                                      : isOverBudget
                                          ? 'You have exceeded your ${_selectedViewPeriod.toLowerCase()} budget by ${formatPeso(remainingBudget.abs())}!'
                                          : '${(progress * 100).toStringAsFixed(1)}% of ${_selectedViewPeriod.toLowerCase()} budget used',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isOverBudget
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isOverBudget
                                        ? AppColors.danger
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. CONFIGURED ALLOWANCES TIERS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Configured Allowances',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showEditBudgetDialog(budget),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: const Text('Edit Budgets'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        _buildBudgetTierTile(
                          title: 'Daily Budget',
                          subtitle: 'Recommended daily spending limit',
                          amount: budget.dailyBudget,
                          icon: Icons.today_rounded,
                          accentColor: AppColors.primary,
                          isActive: _selectedViewPeriod == 'Daily',
                          onTap: () => setState(() => _selectedViewPeriod = 'Daily'),
                        ),
                        _buildBudgetTierTile(
                          title: 'Weekly Budget',
                          subtitle: '7-day allowance allocation',
                          amount: budget.weeklyBudget,
                          icon: Icons.date_range_rounded,
                          accentColor: AppColors.secondary,
                          isActive: _selectedViewPeriod == 'Weekly',
                          onTap: () => setState(() => _selectedViewPeriod = 'Weekly'),
                        ),
                        _buildBudgetTierTile(
                          title: 'Monthly Budget',
                          subtitle: 'Full month allowance allocation',
                          amount: budget.monthlyBudget,
                          icon: Icons.calendar_month_rounded,
                          accentColor: const Color(0xFF22D3EE),
                          isActive: _selectedViewPeriod == 'Monthly',
                          onTap: () => setState(() => _selectedViewPeriod = 'Monthly'),
                        ),
                        const SizedBox(height: 72),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<BudgetModel>(
        stream: _budgetService.streamUserBudget(),
        builder: (context, snapshot) {
          final currentBudget = snapshot.data ??
              BudgetModel(
                userId: _budgetService.currentUserId,
                dailyBudget: 0,
                weeklyBudget: 0,
                monthlyBudget: 0,
              );
          return FloatingActionButton.extended(
            onPressed: () => _showEditBudgetDialog(currentBudget),
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Set Budget'),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String amountText,
    required Color color,
    bool isBold = false,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          amountText,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetTierTile({
    required String title,
    required String subtitle,
    required double amount,
    required IconData icon,
    required Color accentColor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatPeso(amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}