import 'package:flutter/material.dart';
import '../../models/budget_model.dart';
import '../../services/budget_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();

  @override
  void dispose() {
    _budgetService.dispose();
    super.dispose();
  }

  // Open a Dialog with a validated Form to edit Daily, Weekly, and Monthly budgets
  void _showEditBudgetDialog(BudgetModel currentBudget) {
    final formKey = GlobalKey<FormState>();
    final dailyController = TextEditingController(
      text: currentBudget.dailyBudget > 0
          ? currentBudget.dailyBudget.toStringAsFixed(2)
          : '',
    );
    final weeklyController = TextEditingController(
      text: currentBudget.weeklyBudget > 0
          ? currentBudget.weeklyBudget.toStringAsFixed(2)
          : '',
    );
    final monthlyController = TextEditingController(
      text: currentBudget.monthlyBudget > 0
          ? currentBudget.monthlyBudget.toStringAsFixed(2)
          : '',
    );

    String dialogSelectedPeriod = currentBudget.selectedPeriod;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Student Budget'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter your allowance limits below. Choose which period acts as your primary Total Budget.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: dialogSelectedPeriod,
                        decoration: const InputDecoration(
                          labelText: 'Primary Summary Period',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Daily', child: Text('Daily Budget')),
                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly Budget')),
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly Budget')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => dialogSelectedPeriod = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildAmountField(
                        controller: dailyController,
                        label: 'Daily Budget (₱)',
                        icon: Icons.today,
                      ),
                      const SizedBox(height: 12),
                      _buildAmountField(
                        controller: weeklyController,
                        label: 'Weekly Budget (₱)',
                        icon: Icons.date_range,
                      ),
                      const SizedBox(height: 12),
                      _buildAmountField(
                        controller: monthlyController,
                        label: 'Monthly Budget (₱)',
                        icon: Icons.calendar_month,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isSaving = true);
                      try {
                        await _budgetService.saveBudget(
                          dailyBudget: double.parse(dailyController.text.trim()),
                          weeklyBudget: double.parse(weeklyController.text.trim()),
                          monthlyBudget: double.parse(monthlyController.text.trim()),
                          selectedPeriod: dialogSelectedPeriod,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _budgetService.isAuthenticated
                                    ? 'Budget saved successfully!'
                                    : 'Budget saved for this session.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving budget: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Save Budget'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }
        final parsed = double.tryParse(value.trim());
        if (parsed == null || parsed < 0) {
          return 'Enter a valid non-negative number';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<BudgetModel>(
        stream: _budgetService.streamUserBudget(),
        builder: (context, budgetSnapshot) {
          if (budgetSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (budgetSnapshot.hasError) {
            return Center(
              child: Text('Error loading budget: ${budgetSnapshot.error}'),
            );
          }

          final budget = budgetSnapshot.data ??
              BudgetModel(
                userId: _budgetService.currentUserId,
                dailyBudget: 0,
                weeklyBudget: 0,
                monthlyBudget: 0,
              );

          return StreamBuilder<double>(
            stream: _budgetService.streamTotalExpenses(),
            builder: (context, expenseSnapshot) {
              final totalExpenses = expenseSnapshot.data ?? 0.0;
              final totalBudget = budget.activeTotalBudget;
              final remainingBudget = totalBudget - totalExpenses;
              final isOverBudget = remainingBudget < 0;

              final progress = totalBudget > 0
                  ? (totalExpenses / totalBudget).clamp(0.0, 1.0)
                  : 0.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Period Selector Chips (Daily / Weekly / Monthly)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ['Daily', 'Weekly', 'Monthly'].map((period) {
                        final isSelected = budget.selectedPeriod == period;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text('$period View'),
                            selected: isSelected,
                            onSelected: (selected) async {
                              if (!selected) return;
                              try {
                                await _budgetService.updateSelectedPeriod(period);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error updating budget period: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (!_budgetService.isAuthenticated) ...[
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Not signed in. Budgets are available for this session only and are not synced.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // 1. BUDGET SUMMARY CARD (Total Budget, Total Expenses, Remaining Budget)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Budget Summary (${budget.selectedPeriod})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  isOverBudget
                                      ? Icons.warning_amber_rounded
                                      : Icons.account_balance_wallet,
                                  color: isOverBudget ? Colors.red : Colors.teal,
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              label: 'Total Budget',
                              amount: totalBudget,
                              color: Colors.blueGrey.shade800,
                              isBold: true,
                            ),
                            const SizedBox(height: 10),
                            _buildSummaryRow(
                              label: 'Total Expenses',
                              amount: totalExpenses,
                              color: Colors.orange.shade800,
                            ),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              label: 'Remaining Budget',
                              amount: remainingBudget,
                              color: isOverBudget ? Colors.red : Colors.green.shade700,
                              isBold: true,
                              fontSize: 20,
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade200,
                                color: isOverBudget
                                    ? Colors.red
                                    : (progress > 0.8 ? Colors.orange : Colors.teal),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              totalBudget == 0
                                  ? 'Tap "Edit Budgets" below to set your allowance.'
                                  : isOverBudget
                                  ? 'You have exceeded your ${budget.selectedPeriod.toLowerCase()} budget!'
                                  : '${(progress * 100).toStringAsFixed(1)}% of ${budget.selectedPeriod.toLowerCase()} budget used',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverBudget ? Colors.red : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. STUDENT BUDGET TIERS (Daily, Weekly, Monthly Breakdown)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Configured Allowances',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showEditBudgetDialog(budget),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Budgets'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildBudgetTierTile(
                      title: 'Daily Budget',
                      subtitle: 'Recommended daily spending limit',
                      amount: budget.dailyBudget,
                      icon: Icons.today,
                      isActive: budget.selectedPeriod == 'Daily',
                    ),
                    _buildBudgetTierTile(
                      title: 'Weekly Budget',
                      subtitle: '7-day allowance allocation',
                      amount: budget.weeklyBudget,
                      icon: Icons.date_range,
                      isActive: budget.selectedPeriod == 'Weekly',
                    ),
                    _buildBudgetTierTile(
                      title: 'Monthly Budget',
                      subtitle: 'Full month allowance allocation',
                      amount: budget.monthlyBudget,
                      icon: Icons.calendar_month,
                      isActive: budget.selectedPeriod == 'Monthly',
                    ),
                  ],
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
    required double amount,
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
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
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
    required bool isActive,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: Colors.teal, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.teal.shade50 : Colors.grey.shade100,
          child: Icon(icon, color: isActive ? Colors.teal : Colors.grey.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.teal.shade800 : Colors.black87,
          ),
        ),
      ),
    );
  }
}