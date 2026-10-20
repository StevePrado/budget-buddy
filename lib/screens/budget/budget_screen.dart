import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/budget_model.dart';
import '../../models/expense_model.dart';
import '../../services/budget_service.dart';
import '../../services/expense_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/money_format.dart';
import '../../utils/period_helper.dart';
import '../../widgets/confirm_dialog.dart';

String _formatBudgetSynced(double value) {
  if (value < 0) return '';
  return NumberFormat('#,##0.00').format(value);
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

/// Global dialog function to set/edit student budget (Section 4)
Future<void> showSetBudgetDialog(
  BuildContext context, {
  BudgetModel? currentBudget,
}) async {
  BudgetModel? effectiveBudget = currentBudget;
  effectiveBudget ??= await BudgetService().getBudget();

  if (!context.mounted) return;

  final formKey = GlobalKey<FormState>();

  final dailyController = TextEditingController(
    text: effectiveBudget != null
        ? formatAmountForInput(effectiveBudget.dailyBudget, allowZero: true)
        : '',
  );
  final weeklyController = TextEditingController(
    text: effectiveBudget != null
        ? formatAmountForInput(effectiveBudget.weeklyBudget, allowZero: true)
        : '',
  );
  final monthlyController = TextEditingController(
    text: effectiveBudget != null
        ? formatAmountForInput(effectiveBudget.monthlyBudget, allowZero: true)
        : '',
  );

  bool isSaving = false;
  bool isSyncing = false;

  void onDailyChanged(String text) {
    if (isSyncing) return;
    isSyncing = true;
    final val = parsePeso(text);
    if (val != null && val >= 0) {
      weeklyController.text = _formatBudgetSynced(val * 7);
      weeklyController.selection = TextSelection.collapsed(
        offset: weeklyController.text.length,
      );
      monthlyController.text = _formatBudgetSynced(val * 30);
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
    if (val != null && val >= 0) {
      dailyController.text = _formatBudgetSynced(val / 7);
      dailyController.selection = TextSelection.collapsed(
        offset: dailyController.text.length,
      );
      monthlyController.text = _formatBudgetSynced(val * 4);
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
    if (val != null && val >= 0) {
      dailyController.text = _formatBudgetSynced(val / 30);
      dailyController.selection = TextSelection.collapsed(
        offset: dailyController.text.length,
      );
      weeklyController.text = _formatBudgetSynced((val / 30) * 7);
      weeklyController.selection = TextSelection.collapsed(
        offset: weeklyController.text.length,
      );
    }
    isSyncing = false;
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
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
                        // 4.1 & 4.3: Header Row with title on left and X button on right (40x40 area)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Set Student Budget',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                splashRadius: 20,
                                padding: EdgeInsets.zero,
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.pop(ctx),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
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

                        // 4.2: Bottom row with Reset on left and Save Budget on right
                        Row(
                          children: [
                            // Left button: Reset (outlined red, with confirmation)
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          final confirmed =
                                              await showAppConfirmDialog(
                                            context: ctx,
                                            title: 'Reset Fields?',
                                            message:
                                                'Are you sure you want to clear all budget input fields?',
                                            cancelText: 'Cancel',
                                            confirmText: 'Reset',
                                            confirmColor: AppColors.danger,
                                          );
                                          if (confirmed == true) {
                                            dailyController.clear();
                                            weeklyController.clear();
                                            monthlyController.clear();
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(
                                      color: AppColors.danger,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Right button: Save Budget (filled primary)
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          final dailyText =
                                              dailyController.text.trim();
                                          final weeklyText =
                                              weeklyController.text.trim();
                                          final monthlyText =
                                              monthlyController.text.trim();

                                          // 2.1: Block empty fields
                                          if (dailyText.isEmpty ||
                                              weeklyText.isEmpty ||
                                              monthlyText.isEmpty) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please fill in all budget fields with valid amounts.',
                                                ),
                                                backgroundColor:
                                                    AppColors.danger,
                                              ),
                                            );
                                            return;
                                          }

                                          final daily = parsePeso(dailyText);
                                          final weekly = parsePeso(weeklyText);
                                          final monthly =
                                              parsePeso(monthlyText);

                                          // 2.1: Block non-numeric values
                                          if (daily == null ||
                                              weekly == null ||
                                              monthly == null) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please enter valid numeric amounts.',
                                                ),
                                                backgroundColor:
                                                    AppColors.danger,
                                              ),
                                            );
                                            return;
                                          }

                                          // 2.1: 0 is valid, block negative numbers
                                          if (daily < 0 ||
                                              weekly < 0 ||
                                              monthly < 0) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Budget amounts cannot be negative.',
                                                ),
                                                backgroundColor:
                                                    AppColors.danger,
                                              ),
                                            );
                                            return;
                                          }

                                          // 2.1: Order rule Daily <= Weekly <= Monthly
                                          if (!(daily <= weekly &&
                                              weekly <= monthly)) {
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Daily must be less than or equal to Weekly, and Weekly less than or equal to Monthly',
                                                ),
                                                backgroundColor:
                                                    AppColors.danger,
                                              ),
                                            );
                                            return;
                                          }

                                          setDialogState(
                                              () => isSaving = true);
                                          try {
                                            await BudgetService().saveBudget(
                                              dailyBudget: daily,
                                              weeklyBudget: weekly,
                                              monthlyBudget: monthly,
                                              selectedPeriod: effectiveBudget
                                                      ?.selectedPeriod ??
                                                  'Monthly',
                                            );
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx);
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
                                            if (ctx.mounted) {
                                              ScaffoldMessenger.of(ctx)
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Setup & Summary'),
        centerTitle: true,
      ),
      body: StreamBuilder<BudgetModel?>(
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

          final budget = budgetSnapshot.data;
          final hasBudget = budget != null;

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

              // 2.2: Division by zero safe progress calculation
              final progress = PeriodHelper.calculateProgress(
                spent: periodExpenses,
                totalBudget: totalBudget,
              );
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
                                  !hasBudget
                                      ? 'Tap "Set Budget" below to set your allowance.'
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
                              onPressed: () => showSetBudgetDialog(context, currentBudget: budget),
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: Text(hasBudget ? 'Edit Budgets' : 'Set Budget'),
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
                          amount: budget?.dailyBudget ?? 0.0,
                          icon: Icons.today_rounded,
                          accentColor: AppColors.primary,
                          isActive: _selectedViewPeriod == 'Daily',
                          onTap: () => setState(() => _selectedViewPeriod = 'Daily'),
                        ),
                        _buildBudgetTierTile(
                          title: 'Weekly Budget',
                          subtitle: '7-day allowance allocation',
                          amount: budget?.weeklyBudget ?? 0.0,
                          icon: Icons.date_range_rounded,
                          accentColor: AppColors.secondary,
                          isActive: _selectedViewPeriod == 'Weekly',
                          onTap: () => setState(() => _selectedViewPeriod = 'Weekly'),
                        ),
                        _buildBudgetTierTile(
                          title: 'Monthly Budget',
                          subtitle: 'Full month allowance allocation',
                          amount: budget?.monthlyBudget ?? 0.0,
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
      floatingActionButton: StreamBuilder<BudgetModel?>(
        stream: _budgetService.streamUserBudget(),
        builder: (context, snapshot) {
          final currentBudget = snapshot.data;
          return FloatingActionButton.extended(
            onPressed: () => showSetBudgetDialog(context, currentBudget: currentBudget),
            icon: const Icon(Icons.calculate_outlined),
            label: Text(currentBudget == null ? 'Set Budget' : 'Edit Budgets'),
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